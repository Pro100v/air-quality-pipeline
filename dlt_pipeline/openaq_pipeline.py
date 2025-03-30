import os
import dlt
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Generator, Any
import logging
import argparse

# Настройка логирования
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Параметры по умолчанию
DEFAULT_API_ENDPOINT = "https://api.openaq.org/v2"
DEFAULT_LIMIT = 10000
DEFAULT_PAGE = 1
DEFAULT_DAYS = 7  # Данные за последние 7 дней
DEFAULT_PARAMETERS = ["pm25", "pm10", "o3", "no2", "so2", "co"]  # Загрязнители


def parse_args():
    """Парсинг аргументов командной строки"""
    parser = argparse.ArgumentParser(description="OpenAQ API Data Pipeline")
    parser.add_argument(
        "--api-endpoint",
        type=str,
        default=DEFAULT_API_ENDPOINT,
        help=f"OpenAQ API endpoint (default: {DEFAULT_API_ENDPOINT})",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help=f"Number of records per page (default: {DEFAULT_LIMIT})",
    )
    parser.add_argument(
        "--page",
        type=int,
        default=DEFAULT_PAGE,
        help=f"Starting page (default: {DEFAULT_PAGE})",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=DEFAULT_DAYS,
        help=f"Number of days of data to fetch (default: {DEFAULT_DAYS})",
    )
    parser.add_argument(
        "--parameters",
        type=str,
        nargs="+",
        default=DEFAULT_PARAMETERS,
        help=f"Air quality parameters to fetch (default: {DEFAULT_PARAMETERS})",
    )
    parser.add_argument(
        "--countries", type=str, nargs="+", help="Filter by countries (ISO codes)"
    )
    parser.add_argument("--cities", type=str, nargs="+", help="Filter by cities")
    parser.add_argument(
        "--destination",
        type=str,
        default="bigquery",
        help="Destination for the data (bigquery or gcs)",
    )
    return parser.parse_args()


def get_openaq_measurements(
    api_endpoint: str,
    limit: int = DEFAULT_LIMIT,
    page: int = DEFAULT_PAGE,
    days_back: int = DEFAULT_DAYS,
    parameters: List[str] = None,
    countries: List[str] = None,
    cities: List[str] = None,
) -> Generator[Dict[str, Any], None, None]:
    """
    Генератор для получения измерений качества воздуха из OpenAQ API.
    Постранично запрашивает данные и возвращает записи по одной.
    """
    parameters = parameters or DEFAULT_PARAMETERS

    # Вычисление дат для фильтрации
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days_back)

    date_from = start_date.strftime("%Y-%m-%d")
    date_to = end_date.strftime("%Y-%m-%d")

    logger.info(f"Fetching data from {date_from} to {date_to}")

    current_page = page
    has_next_page = True

    while has_next_page:
        # Формирование параметров запроса
        params = {
            "limit": limit,
            "page": current_page,
            "date_from": date_from,
            "date_to": date_to,
            "parameter": parameters,
            "order_by": "datetime",
            "sort": "asc",
            "has_geo": "true",  # Только записи с географическими координатами
        }

        # Добавление фильтров по странам и городам, если указаны
        if countries:
            params["country"] = countries
        if cities:
            params["city"] = cities

        url = f"{api_endpoint}/measurements"

        try:
            logger.info(f"Requesting page {current_page} from {url}")
            response = requests.get(url, params=params)
            response.raise_for_status()  # Проверка на ошибки HTTP

            data = response.json()

            # Проверка наличия данных и метаданных
            if "results" not in data or "meta" not in data:
                logger.warning(f"Unexpected API response format: {data}")
                break

            results = data["results"]
            meta = data["meta"]

            if not results:
                logger.info("No results returned, ending pagination")
                break

            logger.info(f"Received {len(results)} records")

            # Добавление временной метки загрузки данных
            ingestion_timestamp = datetime.utcnow().isoformat()

            # Обработка каждой записи
            for item in results:
                item["ingestion_timestamp"] = ingestion_timestamp
                yield item

            # Проверка наличия следующей страницы
            current_page += 1
            total_pages = meta.get("pages", 0)
            has_next_page = current_page <= total_pages

            logger.info(f"Page {current_page - 1}/{total_pages} processed")

        except requests.RequestException as e:
            logger.error(f"API request error: {str(e)}")
            # Повторный запрос через некоторое время
            import time

            time.sleep(5)
            continue
        except Exception as e:
            logger.error(f"Error processing data: {str(e)}")
            break


@dlt.source
def openaq_source(
    api_endpoint: str = DEFAULT_API_ENDPOINT,
    limit: int = DEFAULT_LIMIT,
    page: int = DEFAULT_PAGE,
    days: int = DEFAULT_DAYS,
    parameters: List[str] = None,
    countries: List[str] = None,
    cities: List[str] = None,
):
    """Определение источника данных dlt для OpenAQ API"""

    @dlt.resource(write_disposition="append")
    def measurements():
        """Ресурс для измерений качества воздуха"""
        yield from get_openaq_measurements(
            api_endpoint=api_endpoint,
            limit=limit,
            page=page,
            days_back=days,
            parameters=parameters,
            countries=countries,
            cities=cities,
        )

    return measurements


def setup_destination(destination_type):
    """Настройка назначения данных"""
    if destination_type.lower() == "bigquery":
        # Настройка для BigQuery
        return dlt.destinations.bigquery(
            dataset="air_quality_dataset",
            location="EU",
        )
    elif destination_type.lower() == "gcs":
        # Настройка для Google Cloud Storage
        return dlt.destinations.filesystem(
            root_path=os.environ.get(
                "GCS_BUCKET_PATH", "gs://air-quality-data-lake-de-zoomcamp-air-quality/"
            )
        )
    else:
        raise ValueError(f"Unsupported destination type: {destination_type}")


def main():
    """Основная функция для запуска пайплайна"""
    args = parse_args()

    logger.info(f"Starting OpenAQ data pipeline with destination: {args.destination}")

    # Инициализация источника данных
    openaq = openaq_source(
        api_endpoint=args.api_endpoint,
        limit=args.limit,
        page=args.page,
        days=args.days,
        parameters=args.parameters,
        countries=args.countries,
        cities=args.cities,
    )

    # Настройка назначения
    destination = setup_destination(args.destination)

    # Запуск пайплайна
    pipeline = dlt.pipeline(
        pipeline_name="openaq_pipeline",
        destination=destination,
        dataset_name="air_quality_data",
        full_refresh=False,  # Инкрементальная загрузка
    )

    # Загрузка данных
    info = pipeline.run(openaq)

    logger.info(f"Pipeline run completed: {info}")
    logger.info(f"Loaded {info.load_package.load_counts} measurements")


if __name__ == "__main__":
    main()
