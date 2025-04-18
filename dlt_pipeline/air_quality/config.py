# dlt_pipeline/air_quality/config.py
import os
import datetime
from typing import Optional
from dataclasses import dataclass


@dataclass
class APIConfig:
    """Конфигурация для API IQAir"""

    api_key: str
    base_url: str = "http://api.airvisual.com/v2"
    request_delay: float = 1.0  # задержка между запросами в секундах
    max_retries: int = 3  # максимальное повторных попыток при ошибке


@dataclass
class DataLakeConfig:
    """Конфигурация для Data Lake"""

    # Локальное хранилище или GCS
    storage_type: str  # 'local' для локальной разработки, 'gcs' для облака

    # Базовый путь для хранения данных
    # Для local: путь к директории
    # Для gcs: gs://bucket-name/path
    base_path: str

    # Формат партиционирования
    partition_format: str = "year=%Y/month=%m/day=%d"

    # GCP настройки (только для GCS)
    project_id: Optional[str] = None
    credentials_path: Optional[str] = None

    # Частота обновления
    update_frequency: str = "daily"  # 'daily', 'weekly', 'monthly'

    # Ограничения для тестирования
    countries_limit: Optional[int] = None
    states_per_country_limit: Optional[int] = None
    cities_per_state_limit: Optional[int] = None

    def get_partition_path(self, data_type: str) -> str:
        """Возвращает путь для сохранения данных с партиционированием по текущей дате"""
        today = datetime.datetime.now()
        date_partition = today.strftime(self.partition_format)
        date_str = today.strftime("%Y%m%d")

        return f"{self.base_path}/{data_type}/{date_partition}/{data_type}_{date_str}.parquet"


def load_config_from_env() -> tuple[APIConfig, DataLakeConfig]:
    """Загрузка конфигурации из переменных окружения"""
    # API конфигурация
    api_key = os.getenv("IQAIR_API_KEY")
    if not api_key:
        raise ValueError("IQAIR_API_KEY не определен в переменных окружения")

    base_url = os.getenv("IQAIR_API_BASE_URL", "http://api.airvisual.com/v2")
    request_delay = float(os.getenv("IQAIR_API_REQUEST_DELAY", "1.0"))
    max_retries = int(os.getenv("IQAIR_API_MAX_RETRIES", "3"))

    api_config = APIConfig(
        api_key=api_key,
        base_url=base_url,
        request_delay=request_delay,
        max_retries=max_retries,
    )

    # Data Lake конфигурация
    storage_type = os.getenv("STORAGE_TYPE", "local")

    # Определяем базовый путь в зависимости от типа хранилища
    if storage_type == "local":
        base_path = os.getenv("LOCAL_DATA_PATH", "./data")
    else:  # gcs
        bucket_name = os.getenv("GCS_BUCKET_NAME")
        project_path = os.getenv("GCS_PROJECT_PATH", "air-quality")
        base_path = f"gs://{bucket_name}/{project_path}"

    # Дополнительные параметры
    project_id = os.getenv("GCP_PROJECT_ID")
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    # Ограничения для тестирования
    countries_limit = os.getenv("DLT_COUNTRIES_LIMIT")
    countries_limit = int(countries_limit) if countries_limit else None

    states_limit = os.getenv("DLT_STATES_PER_COUNTRY_LIMIT")
    states_limit = int(states_limit) if states_limit else None

    cities_limit = os.getenv("DLT_CITIES_PER_STATE_LIMIT")
    cities_limit = int(cities_limit) if cities_limit else None

    datalake_config = DataLakeConfig(
        storage_type=storage_type,
        base_path=base_path,
        project_id=project_id,
        credentials_path=credentials_path,
        countries_limit=countries_limit,
        states_per_country_limit=states_limit,
        cities_per_state_limit=cities_limit,
        update_frequency=os.getenv("UPDATE_FREQUENCY", "daily"),
    )

    return api_config, datalake_config
