#!/bin/bash
set -e

echo "Инициализация Google Cloud SDK..."

# Проверяем наличие credentials.json
if [ ! -f "/app/secrets/credentials.json" ]; then
  echo "Ошибка: файл credentials.json не найден."
  echo "Пожалуйста, поместите файл credentials.json в папку secrets."
  exit 1
fi

# Активируем сервисный аккаунт
gcloud auth activate-service-account --key-file=/app/secrets/credentials.json

# Устанавливаем текущий проект
PROJECT_ID=$(cat /app/secrets/credentials.json | jq -r '.project_id')
if [ -z "$PROJECT_ID" ]; then
  echo "Не удалось определить project_id из credentials.json"
  echo "Пожалуйста, введите ID проекта GCP:"
  read PROJECT_ID
fi

gcloud config set project $PROJECT_ID
echo "Google Cloud SDK настроен для проекта: $PROJECT_ID"

# Проверяем, существует ли Service Account
SA_EMAIL="air-quality-sa@$PROJECT_ID.iam.gserviceaccount.com"
SA_EXISTS=$(gcloud iam service-accounts list --filter="email:$SA_EMAIL" --format="value(email)")

if [ -z "$SA_EXISTS" ]; then
  echo "Сервисный аккаунт $SA_EMAIL не существует. Создаем..."

  # Создаем Service Account
  gcloud iam service-accounts create air-quality-sa \
    --display-name="Air Quality Pipeline Service Account" \
    --description="Service Account for Air Quality Data Pipeline"

  # Добавляем необходимые роли
  echo "Назначаем роли для сервисного аккаунта..."

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

  echo "Сервисный аккаунт $SA_EMAIL создан и настроен."
else
  echo "Сервисный аккаунт $SA_EMAIL уже существует."
fi

echo "Инициализация Google Cloud SDK завершена успешно!"
