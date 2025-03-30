#!/bin/bash
set -e

# Скрипт для установки зависимостей Kestra

# Директория для плагинов
PLUGINS_DIR="/opt/kestra/plugins"
mkdir -p $PLUGINS_DIR

# Установка плагинов
echo "Установка плагинов Kestra..."

# Плагин для PostgreSQL
wget -O $PLUGINS_DIR/postgresql.jar https://repo.maven.apache.org/maven2/io/kestra/plugin/plugin-jdbc-postgresql/0.15.0/plugin-jdbc-postgresql-0.15.0.jar

# Плагин для GCS
wget -O $PLUGINS_DIR/gcs.jar https://repo.maven.apache.org/maven2/io/kestra/storage/storage-gcs/0.15.0/storage-gcs-0.15.0.jar

# Плагин для Slack
wget -O $PLUGINS_DIR/slack.jar https://repo.maven.apache.org/maven2/io/kestra/plugin/plugin-notifications-slack/0.15.0/plugin-notifications-slack-0.15.0.jar

# Плагин для BigQuery
wget -O $PLUGINS_DIR/bigquery.jar https://repo.maven.apache.org/maven2/io/kestra/plugin/plugin-gcp-bigquery/0.15.0/plugin-gcp-bigquery-0.15.0.jar

# Плагин для Python
wget -O $PLUGINS_DIR/python.jar https://repo.maven.apache.org/maven2/io/kestra/plugin/plugin-scripts-python/0.15.0/plugin-scripts-python-0.15.0.jar

# Плагин для Shell
wget -O $PLUGINS_DIR/shell.jar https://repo.maven.apache.org/maven2/io/kestra/plugin/plugin-scripts-shell/0.15.0/plugin-scripts-shell-0.15.0.jar

echo "Установка плагинов завершена!"
