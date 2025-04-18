#!/bin/bash

# Install required Python packages for the pipeline
pip install dlt~=1.9.0 requests pandas

# Install DBT and its dependencies
pip install dbt-core dbt-bigquery
