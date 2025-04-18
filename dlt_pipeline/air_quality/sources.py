# dlt_pipeline/air_quality/sources.py
import time
import requests
from typing import Iterator, Dict, Any, Optional, List
from .config import APIConfig


class IQAirAPI:
    """Класс для взаимодействия с API IQAir"""

    def __init__(self, config: APIConfig):
        self.config = config
        self.session = requests.Session()

    def _make_request(
        self, endpoint: str, params: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Выполняет запрос к API с повторными попытками"""
        if params is None:
            params = {}

        # Добавляем API ключ к параметрам
        params["key"] = self.config.api_key

        # Формируем полный URL
        url = f"{self.config.base_url}/{endpoint}"

        # Повторные попытки при ошибках
        retries = 0
        while retries <= self.config.max_retries:
            try:
                response = self.session.get(url, params=params)
                response.raise_for_status()  # Вызывает исключение для 4xx/5xx статусов

                data = response.json()

                # Проверяем статус ответа
                if data.get("status") != "success":
                    raise ValueError(f"API вернул ошибку: {data.get('data')}")

                return data

            except (requests.RequestException, ValueError) as e:
                retries += 1
                if retries > self.config.max_retries:
                    raise

                # Увеличиваем задержку с каждой повторной попыткой
                wait_time = self.config.request_delay * (2 ** (retries - 1))
                print(
                    f"Ошибка запроса ({str(e)}), повторная попытка через {wait_time} сек..."
                )
                time.sleep(wait_time)

        # Этот код не должен выполняться (защита от ошибок)
        raise RuntimeError("Неожиданная ошибка в _make_request")

    def get_countries(self) -> List[Dict[str, str]]:
        """Получает список всех доступных стран"""
        response = self._make_request("countries")
        countries = response.get("data", [])

        # Добавляем метку времени к каждой стране
        timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        for country in countries:
            country["timestamp"] = timestamp

        return countries

    def get_states(self, country: str) -> List[Dict[str, str]]:
        """Получает список штатов/регионов для указанной страны"""
        response = self._make_request("states", {"country": country})
        states = response.get("data", [])

        # Добавляем страну и метку времени к каждому штату
        timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        for state in states:
            state["country"] = country
            state["timestamp"] = timestamp

        # Задержка для соблюдения ограничений API
        time.sleep(self.config.request_delay)

        return states

    def get_cities(self, country: str, state: str) -> List[Dict[str, str]]:
        """Получает список городов для указанного штата/региона"""
        response = self._make_request("cities", {"country": country, "state": state})
        cities = response.get("data", [])

        # Добавляем страну, штат и метку времени к каждому городу
        timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        for city in cities:
            city["country"] = country
            city["state"] = state
            city["timestamp"] = timestamp

        # Задержка для соблюдения ограничений API
        time.sleep(self.config.request_delay)

        return cities

    def get_city_data(self, country: str, state: str, city: str) -> Dict[str, Any]:
        """Получает данные о качестве воздуха для указанного города"""
        response = self._make_request(
            "city", {"country": country, "state": state, "city": city}
        )

        city_data = response.get("data", {})

        # Преобразуем данные для удобства хранения
        result = {
            "city": city,
            "state": state,
            "country": country,
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }

        # Добавляем координаты
        if "location" in city_data:
            coordinates = city_data["location"].get("coordinates", [])
            if len(coordinates) >= 2:
                result["longitude"] = coordinates[0]
                result["latitude"] = coordinates[1]

        # Добавляем данные о загрязнении
        if "current" in city_data and "pollution" in city_data["current"]:
            pollution = city_data["current"]["pollution"]
            result["pollution_ts"] = pollution.get("ts")
            result["aqi_us"] = pollution.get("aqius")
            result["main_pollutant_us"] = pollution.get("mainus")
            result["aqi_cn"] = pollution.get("aqicn")
            result["main_pollutant_cn"] = pollution.get("maincn")

        # Добавляем данные о погоде
        if "current" in city_data and "weather" in city_data["current"]:
            weather = city_data["current"]["weather"]
            result["weather_ts"] = weather.get("ts")
            result["temperature"] = weather.get("tp")
            result["pressure"] = weather.get("pr")
            result["humidity"] = weather.get("hu")
            result["wind_speed"] = weather.get("ws")
            result["wind_direction"] = weather.get("wd")
            result["weather_icon"] = weather.get("ic")

        # Задержка для соблюдения ограничений API
        time.sleep(self.config.request_delay)

        return result


# Функции-генераторы для dlt


def yield_countries(
    api_config: APIConfig, limit: Optional[int] = None
) -> Iterator[Dict[str, Any]]:
    """Генератор стран для dlt"""
    api = IQAirAPI(api_config)
    countries = api.get_countries()

    # Применяем ограничение, если указано
    if limit:
        countries = countries[:limit]

    for country in countries:
        yield country


def yield_states(
    api_config: APIConfig, countries: List[str], limit_per_country: Optional[int] = None
) -> Iterator[Dict[str, Any]]:
    """Генератор штатов/регионов для dlt"""
    api = IQAirAPI(api_config)

    for country_name in countries:
        states = api.get_states(country_name)

        # Применяем ограничение, если указано
        if limit_per_country:
            states = states[:limit_per_country]

        for state in states:
            yield state


def yield_cities(
    api_config: APIConfig,
    country_states: List[tuple[str, str]],
    limit_per_state: Optional[int] = None,
) -> Iterator[Dict[str, Any]]:
    """Генератор городов для dlt"""
    api = IQAirAPI(api_config)

    for country_name, state_name in country_states:
        cities = api.get_cities(country_name, state_name)

        # Применяем ограничение, если указано
        if limit_per_state:
            cities = cities[:limit_per_state]

        for city in cities:
            yield city


def yield_air_quality(
    api_config: APIConfig, city_infos: List[tuple[str, str, str]]
) -> Iterator[Dict[str, Any]]:
    """Генератор данных о качестве воздуха для dlt"""
    api = IQAirAPI(api_config)

    for country_name, state_name, city_name in city_infos:
        try:
            city_data = api.get_city_data(country_name, state_name, city_name)
            yield city_data
        except Exception as e:
            print(
                f"Ошибка при получении данных для {city_name}, {state_name}, {country_name}: {str(e)}"
            )
            # Продолжаем с следующим городом
            continue
