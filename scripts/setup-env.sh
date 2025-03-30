#!/bin/bash
set -e

# Скрипт для первоначальной настройки окружения проекта

echo "Начинаем настройку окружения проекта..."

# Создаем директории, если их нет
mkdir -p secrets terraform/modules dlt_pipeline/resources dbt_models/models kestra/flows

# Проверяем наличие файла .env
if [ ! -f ".env" ]; then
  echo "Файл .env не найден. Создаем из примера..."
  if [ -f ".env.example" ]; then
    cp .env.example .env
    echo "Файл .env создан. Пожалуйста, отредактируйте его с вашими настройками."
  else
    echo "Ошибка: файл .env.example не найден!"
    exit 1
  fi
fi

# Проверяем наличие учетных данных GCP
if [ ! -f "secrets/credentials.json" ]; then
  echo "Предупреждение: файл credentials.json не найден в папке secrets."
  echo "Вам необходимо получить ключ сервисного аккаунта GCP и поместить его в secrets/credentials.json."
fi

# Проверяем наличие Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Ошибка: Docker не установлен. Пожалуйста, установите Docker."
  exit 1
fi

# Проверяем наличие Docker Compose
if ! command -v docker compose >/dev/null 2>&1; then
  echo "Ошибка: Docker Compose не установлен. Пожалуйста, установите Docker Compose."
  exit 1
fi

# Проверяем наличие файла terraform.tfvars
if [ ! -f "terraform/terraform.tfvars" ]; then
  echo "Файл terraform/terraform.tfvars не найден. Создаем из примера..."
  if [ -f "terraform/terraform.tfvars.example" ]; then
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    echo "Файл terraform.tfvars создан. Пожалуйста, отредактируйте его с вашими настройками."
  else
    echo "Предупреждение: файл terraform.tfvars.example не найден!"
  fi
fi

echo "Подготовка окружения завершена! Теперь вы можете запустить 'make docker-build' для сборки контейнеров."
