# Air Quality Data Pipeline

Конвейер данных для сбора, обработки и визуализации данных о качестве воздуха с использованием OpenAQ API.

## Обзор проекта

Этот проект создает полный конвейер данных для:
1. Извлечения данных о качестве воздуха из API OpenAQ
2. Загрузки данных в GCS Data Lake
3. Трансформации данных в BigQuery
4. Визуализации данных на дашборде

## Архитектура

Архитектура проекта включает следующие компоненты:
- **Источник данных**: OpenAQ API
- **Инструмент извлечения данных**: dltHub
- **Data Lake**: Google Cloud Storage (GCS)
- **Data Warehouse**: BigQuery
- **Инструмент трансформации данных**: dbt
- **Оркестрация**: Kestra
- **Инфраструктура как код**: Terraform

## Технологии

- **Облако**: Google Cloud Platform (GCP)
- **Инфраструктура как код**: Terraform
- **Оркестрация рабочих потоков**: Kestra
- **Извлечение данных**: dltHub
- **Трансформация данных**: dbt
- **Хранилище данных**: BigQuery
- **Визуализация**: Looker Studio

## Предварительные требования

- Google Cloud Platform аккаунт
- Для локальной разработки:
  - Docker и Docker Compose
  - Make

## Быстрый старт с Docker

1. Клонировать репозиторий:
   ```bash
   git clone https://github.com/yourusername/air-quality-pipeline.git
   cd air-quality-pipeline
   ```

2. Запустите скрипт настройки окружения:
   ```bash
   chmod +x scripts/setup-env.sh
   ./scripts/setup-env.sh
   ```
   
   Этот скрипт создаст необходимую структуру директорий и файл `.env` из примера.

3. Отредактируйте файл `.env`, указав ваш идентификатор проекта GCP и другие настройки:
   ```
   GCP_PROJECT_ID=de-zoomcamp-air-quality
   GOOGLE_APPLICATION_CREDENTIALS=./secrets/credentials.json
   BIGQUERY_DATASET=air_quality_dataset
   BIGQUERY_LOCATION=EU
   GCS_BUCKET_PATH=gs://air-quality-data-lake-de-zoomcamp-air-quality
   ```

4. Создайте сервисный аккаунт GCP и поместите ключ в папку `secrets`:
   ```bash
   chmod +x scripts/create-sa-gcloud.sh
   ./scripts/create-sa-gcloud.sh
   ```

5. Собрать и запустить Docker контейнеры:
   ```bash
   make docker-build
   make docker-up
   ```

6. Инициализировать Google Cloud SDK в контейнере Terraform:
   ```bash
   make docker-init-gcloud
   ```
   
   Этот шаг также создаст сервисный аккаунт с нужными правами, если он еще не существует.

7. Применить Terraform конфигурацию для создания инфраструктуры:
   ```bash
   make docker-exec-terraform
   cd /app/terraform && terraform apply
   ```

8. Запустить конвейер данных:
   ```bash
   make docker-run-dlt      # Извлечение данных
   make docker-run-dbt      # Трансформация данных
   ```

9. Доступ к интерфейсам:
   - Kestra UI: http://localhost:8080
   - dbt Docs: http://localhost:8580

## Использование Makefile

Проект включает Makefile для упрощения общих операций:

### Стандартные команды
- `make help`: Показать список доступных команд
- `make setup`: Настроить окружение для проекта
- `make init-terraform`: Инициализировать Terraform
- `make apply-terraform`: Применить конфигурацию Terraform
- `make destroy-terraform`: Удалить инфраструктуру, созданную Terraform
- `make run-kestra`: Запустить сервер Kestra
- `make run-dlt-pipeline`: Запустить dlt pipeline
- `make run-dbt`: Запустить dbt модели
- `make clean`: Очистить временные файлы
- `make all`: Запустить полный пайплайн

### Docker команды
- `make docker-build`: Собрать Docker образы
- `make docker-up`: Запустить все Docker контейнеры
- `make docker-down`: Остановить все Docker контейнеры
- `make docker-logs`: Показать логи Docker контейнеров
- `make docker-exec-dlt`: Войти в контейнер dltHub
- `make docker-exec-dbt`: Войти в контейнер dbt
- `make docker-exec-terraform`: Войти в контейнер Terraform
- `make docker-init-gcloud`: Инициализировать Google Cloud SDK в контейнере Terraform
- `make docker-run-dlt`: Запустить dlt pipeline в контейнере
- `make docker-run-dbt`: Запустить dbt модели в контейнере
- `make docker-all`: Запустить полный пайплайн в Docker

## Настройка

### Terraform

Основные настройки проекта находятся в файле `terraform/terraform.tfvars`. Скопируйте пример конфигурации и настройте по своим требованиям:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Затем отредактируйте файл, указав ваш идентификатор проекта GCP и другие параметры.

### dltHub

Параметры извлечения данных можно настроить в `dlt_pipeline/openaq_pipeline.py`. Вы можете указать:
- Параметры качества воздуха для сбора
- Страны и города для фильтрации
- Период сбора данных

### dbt

Модели dbt настроены для преобразования сырых данных в аналитические представления. При необходимости вы можете настроить профили подключения в `dbt_models/profiles.yml`.

### Kestra

Потоки Kestra для оркестрации находятся в директории `kestra/flows/`. Вы можете настроить расписание и параметры выполнения.

## Разработка с использованием Docker

Проект настроен для удобной разработки с использованием Docker:

1. **Монтирование исходного кода**: Все исходные коды монтируются в соответствующие контейнеры, что позволяет редактировать файлы на хост-машине и сразу видеть изменения в контейнерах.

2. **Доступ к контейнерам**:
   - Для доступа к контейнеру dltHub: `make docker-exec-dlt`
   - Для доступа к контейнеру dbt: `make docker-exec-dbt`
   - Для доступа к контейнеру Terraform: `make docker-exec-terraform`

3. **Запуск компонентов внутри контейнеров**:
   - Для запуска dlt pipeline: `make docker-run-dlt`
   - Для запуска dbt моделей: `make docker-run-dbt`

4. **Доступ к интерфейсам**:
   - Kestra UI: http://localhost:8080
   - dbt Docs: http://localhost:8580

## Структура проекта

```
air-quality-pipeline/
├── .github/                     # GitHub Actions конфигурации
├── secrets/                     # Папка для хранения секретов
├── scripts/                     # Bash скрипты для проекта
│   ├── init-gcloud.sh           # Скрипт для инициализации gcloud
│   ├── create-sa-gcloud.sh      # Скрипт для создания сервисного аккаунта
│   └── setup-env.sh             # Скрипт для настройки окружения
├── terraform/                   # Terraform конфигурации
├── dlt_pipeline/                # dltHub пайплайн
├── dbt_models/                  # dbt модели
├── kestra/                      # Kestra workflows
├── docker/                      # Файлы Docker
├── Makefile                     # Команды для управления проектом
├── docker-compose.yml           # Docker Compose конфигурация
├── README.md                    # Документация проекта
└── requirements.txt             # Зависимости Python
```

## Примечания и рекомендации

- Для продакшн среды рекомендуется настроить более строгие правила доступа в Terraform
- Рассмотрите возможность усовершенствования мониторинга с помощью GCP Cloud Monitoring
- Для обработки больших объемов данных можно масштабировать инфраструктуру, изменив типы машин в terraform.tfvars
- При использовании Docker убедитесь, что вы корректно настроили файл `.env` и предоставили доступ к файлу учетных данных GCP

## Устранение неполадок

Если вы столкнулись с проблемами:

1. Проверьте логи Docker контейнеров: `make docker-logs`
2. Убедитесь, что ваш сервисный аккаунт имеет необходимые разрешения
3. Проверьте квоты GCP
4. Проверьте правильность настроек в файле .env

## Лицензия

MIT
