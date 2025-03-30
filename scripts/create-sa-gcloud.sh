#!/bin/bash
set -e

# Скрипт для создания проекта GCP и сервисного аккаунта

# Проверяем, установлен ли gcloud
if ! command -v gcloud &>/dev/null; then
  echo "gcloud не установлен. Пожалуйста, установите Google Cloud SDK."
  exit 1
fi

echo "Убедитесь, что вы авторизованы в gcloud CLI:"
gcloud auth list

echo "Текущий GCP проект:"
gcloud config get-value project

# Запрашиваем ID проекта
read -p "Введите ID проекта GCP (default: de-zoomcamp-air-quality): " PROJECT_ID
PROJECT_ID=${PROJECT_ID:-de-zoomcamp-air-quality}

# Запрашиваем название сервисного аккаунта
read -p "Введите название сервисного аккаунта (default: air-quality-sa): " SA_NAME
SA_NAME=${SA_NAME:-air-quality-sa}

# Создание проекта (если не существует)
if ! gcloud projects describe $PROJECT_ID &>/dev/null; then
  echo "Создание проекта $PROJECT_ID..."
  gcloud projects create $PROJECT_ID --name="Air Quality Monitoring"

  # Запрос ID платежного аккаунта
  echo "Список доступных платежных аккаунтов:"
  gcloud billing accounts list
  read -p "Введите ID платежного аккаунта для проекта: " BILLING_ACCOUNT_ID

  # Привязка платежного аккаунта
  echo "Привязка платежного аккаунта к проекту..."
  gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
else
  echo "Проект $PROJECT_ID уже существует."
fi

# Устанавливаем проект по умолчанию
gcloud config set project $PROJECT_ID

# Включение необходимых API
echo "Включение необходимых API в проекте..."
gcloud services enable compute.googleapis.com bigquery.googleapis.com storage.googleapis.com iam.googleapis.com

# Создание сервисного аккаунта
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
  echo "Создание сервисного аккаунта $SA_EMAIL..."
  gcloud iam service-accounts create $SA_NAME \
    --display-name="Air Quality Service Account" \
    --description="Service Account for Air Quality Data Pipeline"
else
  echo "Сервисный аккаунт $SA_EMAIL уже существует."
fi

# Назначение необходимых ролей
echo "Назначение ролей для сервисного аккаунта..."
# Storage Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"

# BigQuery Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/bigquery.admin"

# Compute Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/compute.admin"

# Service Account User
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.serviceAccountUser"

# Создание ключа
mkdir -p secrets
echo "Создание и скачивание ключа сервисного аккаунта в secrets/credentials.json..."
gcloud iam service-accounts keys create secrets/credentials.json \
  --iam-account=$SA_EMAIL

echo "Сервисный аккаунт $SA_EMAIL создан и настроен!"
echo "Ключ сохранен в secrets/credentials.json"
echo "Теперь вы можете запустить 'make docker-build' для сборки контейнеров."
