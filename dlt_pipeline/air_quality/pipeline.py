# dlt_pipeline/air_quality/pipeline.py
import os
import dlt
from typing import List, Optional, Dict, Any
from datetime import datetime
from .config import load_config_from_env
from .sources import yield_countries, yield_states, yield_cities, yield_air_quality

def create_pipeline():
    """Создает dlt пайплайн для сбора данных о качестве воздуха"""
    # Загружаем конфигурацию
    api_config, datalake_config = load_config_from_env()
    
    # Возвращаем конфигурацию для использования в run_pipeline
    return api_config, datalake_config

def run_pipeline():
    """Запускает пайплайн для сбора данных и сохранения их в Data Lake"""
    api_config, datalake_config = create_pipeline()
    
    # Сегодняшняя дата для партицирования и именования файлов
    today = datetime.now()
    date_str = today.strftime("%Y%m%d")
    
    # Создаем директории для данных, если они не существуют
    if datalake_config.storage_type == "local":
        os.makedirs(os.path.dirname(datalake_config.get_partition_path("countries")), exist_ok=True)
        os.makedirs(os.path.dirname(datalake_config.get_partition_path("states")), exist_ok=True)
        os.makedirs(os.path.dirname(datalake_config.get_partition_path("cities")), exist_ok=True)
        os.makedirs(os.path.dirname(datalake_config.get_partition_path("air_quality")), exist_ok=True)
    
    # Шаг 1: Загрузка и сохранение стран
    print("Загрузка стран...")
    pipeline_countries = dlt.pipeline(
        pipeline_name=f"countries_{date_str}",
        destination="filesystem",
        dataset_name="countries",
        full_refresh=True
    )
    
    countries_resource = dlt.resource(
        yield_countries,
        name="countries"
    )
    
    countries_info = pipeline_countries.run(
        countries_resource(api_config, datalake_config.countries_limit),
        destination_options={"path": datalake_config.get_partition_path("countries")}
    )
    print(f"Загружено стран: {countries_info.load_package.load_info}")
    
    # Получаем список загруженных стран для следующего шага
    countries_data = countries_info.load_package.data_frames["countries"].to_pandas()
    country_names = countries_data["country"].tolist()
    
    # Шаг 2: Загрузка и сохранение штатов/регионов
    print("Загрузка штатов/регионов...")
    pipeline_states = dlt.pipeline(
        pipeline_name=f"states_{date_str}",
        destination="filesystem",
        dataset_name="states",
        full_refresh=True
    )
    
    states_resource = dlt.resource(
        yield_states,
        name="states"
    )
    
    states_info = pipeline_states.run(
        states_resource(api_config, country_names, datalake_config.states_per_country_limit),
        destination_options={"path": datalake_config.get_partition_path("states")}
    )
    print(f"Загружено штатов/регионов: {states_info.load_package.load_info}")
    
    # Получаем список штатов по странам для следующего шага
    states_data = states_info.load_package.data_frames["states"].to_pandas()
    country_states = states_data[["country", "state"]].itertuples(index=False, name=None)
    
    # Шаг 3: Загрузка и сохранение городов
    print("Загрузка городов...")
    pipeline_cities = dlt.pipeline(
        pipeline_name=f"cities_{date_str}",
        destination="filesystem",
        dataset_name="cities",
        full_refresh=True
    )
    
    cities_resource = dlt.resource(
        yield_cities,
        name="cities"
    )
    
    cities_info = pipeline_cities.run(
        cities_resource(api_config, list(country_states), datalake_config.cities_per_state_limit),
        destination_options={"path": datalake_config.get_partition_path("cities")}
    )
    print(f"Загружено городов: {cities_info.load_package.load_info}")
    
    # Получаем список городов по штатам и странам для следующего шага
    cities_data = cities_info.load_package.data_frames["cities"].to_pandas()
    city_infos = cities_data[["country", "state", "city"]].itertuples(index=False, name=None)
    
    # Шаг 4: Загрузка и сохранение данных о качестве воздуха
    print("Загрузка данных о качестве воздуха...")
    pipeline_air_quality = dlt.pipeline(
        pipeline_name=f"air_quality_{date_str}",
        destination="filesystem",
        dataset_name="air_quality",
        full_refresh=True
    )
    
    air_quality_resource = dlt.resource(
        yield_air_quality,
        name="air_quality"
    )
    
    air_quality_info = pipeline_air_quality.run(
        air_quality_resource(api_config, list(city_infos)),
        destination_options={"path": datalake_config.get_partition_path("air_quality")}
    )
    print(f"Загружено данных о качестве воздуха: {air_quality_info.load_package.load_info}")
    
    print(f"Пайплайн успешно завершен. Все данные сохранены в Data Lake.")
    return True

if __name__ == "__main__":
    run_pipeline()
