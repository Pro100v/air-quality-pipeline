from typing import Any, Dict, List, Optional
import dlt
from dlt.sources.rest_api import rest_api_resources
from dlt.sources.rest_api import RESTAPIConfig
from dlt.sources.helpers.rest_client.auth import APIKeyAuth

from requests_ratelimiter import LimiterSession


def flatten_city_location(doc: dict):
    """Преобразует вложенные поля в плоские."""
    # Получаем данные локации
    # pprint(doc, depth=1)
    location = doc.get("location", {})

    if location and location.get("type") == "Point" and "coordinates" in location:
        # Извлекаем координаты
        coordinates = location["coordinates"]

        # Добавляем плоские поля с понятными именами
        doc["geo_longitude"] = coordinates[0]
        doc["geo_latitude"] = coordinates[1]

        # Можно удалить или оставить исходное вложенное поле
        del doc["location"]

    return doc


def sorted_dict(d):
    """Сортирует словарь по ключам."""
    primitives = (int, float, str, bool)
    primitives_dict = {}
    not_primitives_dict = {}
    for k, v in d.items():
        if isinstance(v, primitives):
            primitives_dict[k] = v
        else:
            not_primitives_dict[k] = v

    return primitives_dict | not_primitives_dict


def remove_columns(doc: Dict, remove_columns: Optional[List[str]] = None) -> Dict:
    if remove_columns is None:
        remove_columns = []

    # Iterating over the list of columns to be removed
    for column_name in remove_columns:
        # Removing the column if it exists in the document
        if column_name in doc:
            del doc[column_name]

    return sorted_dict(doc)


@dlt.source(name="iqair")
def iqair_source(api_key: Optional[str] = dlt.secrets.value) -> Any:
    # Create a REST API configuration for the GitHub API
    # Use RESTAPIConfig to get autocompletion and type checking
    from dlt.sources.helpers.requests.retry import Client
    from requests_ratelimiter import LimiterAdapter

    my_session = Client(raise_for_status=False).session
    adapter = LimiterAdapter(per_second=5)
    my_session.mount("http://", adapter)
    my_session.mount("https://", adapter)
    config: RESTAPIConfig = {
        "client": {
            "base_url": "http://api.airvisual.com/v2",
            "paginator": "single_page",
            # # we add an auth config if the auth token is present
            "auth": APIKeyAuth(name="key", api_key=api_key, location="query"),
            # "session": LimiterSession(per_second=8),
            "session": my_session,
        },
        # The default configuration for all resources and their endpoints
        "resource_defaults": {
            # "primary_key": "id",
            "write_disposition": "replace",
            # "endpoint": {
            #     "params": {
            #         "key": api_key,
            #     },
            # },
        },
        "resources": [
            # This is a simple resource definition,
            # that uses the endpoint path as a resource name:
            # "pulls",
            # Alternatively, you can define the endpoint as a dictionary
            # {
            #     "name": "pulls", # <- Name of the resource
            #     "endpoint": "pulls",  # <- This is the endpoint path
            # }
            # Or use a more detailed configuration:
            {
                "name": "countries",
                "selected": False,
                "endpoint": {
                    "path": "countries",
                    "data_selector": "data",
                    # Query parameters for the endpoint
                    # "params": {
                    #     "sort": "updated",
                    #     "direction": "desc",
                    #     "state": "open",
                    #     # Define `since` as a special parameter
                    #     # to incrementally load data from the API.
                    #     # This works by getting the updated_at value
                    #     # from the previous response data and using this value
                    #     # for the `since` query parameter in the next request.
                    #     "since": "{incremental.start_value}",
                    # },
                    # For incremental to work, we need to define the cursor_path
                    # (the field that will be used to get the incremental value)
                    # and the initial value
                    # "incremental": {
                    #     "cursor_path": "updated_at",
                    #     "initial_value": pendulum.today().subtract(days=30).to_iso8601_string(),
                    # },
                },
                # "processing_steps": [
                #     {"filter": lambda x: list(x.values())[0].lower().startswith("a")},  # type: ignore
                # ],
            },
            # The following is an example of a resource that uses
            # a parent resource (`issues`) to get the `issue_number`
            # and include it in the endpoint path:
            {
                "name": "states",
                "selected": False,
                "endpoint": {
                    # The placeholder `{resources.issues.number}`
                    # will be replaced with the value of `number` field
                    # in the `issues` resource data
                    "path": "states",
                    "data_selector": "data",
                    "params": {
                        "country": "{resources.countries.country}",
                    },
                },
                # "processing_steps": [
                #     {"filter": lambda x: list(x.values())[0].lower().startswith("a")},
                # ],
                # Include data from `id` field of the parent resource
                # in the child data. The field name in the child data
                # will be called `_issues_id` (_{resource_name}_{field_name})
                "include_from_parent": ["country"],
            },
            {
                "name": "cities",
                "selected": False,
                "endpoint": {
                    # The placeholder `{resources.issues.number}`
                    # will be replaced with the value of `number` field
                    # in the `issues` resource data
                    "path": "cities",
                    "data_selector": "data",
                    "params": {
                        "country": "{resources.states._countries_country}",
                        "state": "{resources.states.state}",
                    },
                },
                # "processing_steps": [
                #     {"filter": lambda x: list(x.values())[0].lower().startswith("a")},
                # ],
                # Include data from `id` field of the parent resource
                # in the child data. The field name in the child data
                # will be called `_issues_id` (_{resource_name}_{field_name})
                "include_from_parent": ["_countries_country", "state"],
            },
            {
                "name": "city",
                "endpoint": {
                    # The placeholder `{resources.issues.number}`
                    # will be replaced with the value of `number` field
                    # in the `issues` resource data
                    "path": "city",
                    "data_selector": "data",
                    "params": {
                        "country": "{resources.cities._states_countries_country}",
                        "state": "{resources.cities._states_state}",
                        "city": "{resources.cities.city}",
                    },
                },
                "processing_steps": [
                    {
                        "filter": flatten_city_location,
                    },  # type: ignore
                    {
                        "filter": lambda doc: remove_columns(
                            doc,
                            remove_columns=["forecasts"],
                        )
                    },
                    # {"filter": lambda x: list(x.values())[0].lower().startswith("a")},
                ],
                # Include data from `id` field of the parent resource
                # in the child data. The field name in the child data
                # will be called `_issues_id` (_{resource_name}_{field_name})
                # "include_from_parent": ["country", "state", "city"],
            },
        ],
    }
    # print(f"{config=}")

    yield from rest_api_resources(config)


def load_iqair() -> None:
    pipeline = dlt.pipeline(
        pipeline_name="rest_api_iqair",
        # destination="duckdb",
        destination="filesystem",
        dataset_name="iqair_api_data",
        export_schema_path="schemas/export",
        import_schema_path="schemas/import",
        dev_mode=True,
    )

    iqair_source_instance = iqair_source()
    remove_columns_list = ["forecasts"]
    iqair_source_instance.city.add_map(flatten_city_location).add_map(
        lambda doc: remove_columns(doc, remove_columns=remove_columns_list)
    )

    print(pipeline.destination.config_params)  # noqa: T201
    # return
    load_info = pipeline.run(iqair_source().add_limit(5))
    # load_info = pipeline.run(iqair_source())
    print(load_info)  # noqa: t201


if __name__ == "__main__":
    load_iqair()
