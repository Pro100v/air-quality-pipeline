variable "project_id" {
  description = "ID проекта Google Cloud"
  type        = string
  default     = "de-zoomcamp-air-quality" # Ваш проект
}

variable "region" {
  description = "Регион GCP для развертывания ресурсов"
  type        = string
  default     = "europe-west1" # Европейский регион
}

variable "zone" {
  description = "Зона GCP для развертывания VM"
  type        = string
  default     = "europe-west1-b" # Соответствующая зона
}

variable "data_lake_bucket_name" {
  description = "Название GCS bucket для Data Lake"
  type        = string
  default     = "air-quality-data-lake"
}

variable "kestra_storage_bucket_name" {
  description = "Название GCS bucket для хранилища Kestra"
  type        = string
  default     = "kestra-storage"
}

variable "bigquery_dataset_name" {
  description = "Название BigQuery dataset"
  type        = string
  default     = "air_quality_dataset"
}

variable "bigquery_location" {
  description = "Регион для BigQuery dataset"
  type        = string
  default     = "EU" # Европейское расположение
}

variable "vm_machine_type" {
  description = "Тип машины для VM"
  type        = string
  default     = "e2-medium"
}

variable "vm_name" {
  description = "Название VM инстанса"
  type        = string
  default     = "kestra-orchestrator"
}

variable "sa_name" {
  description = "Название сервисного аккаунта"
  type        = string
  default     = "air-quality-sa"
}

variable "environment" {
  description = "Среда развертывания (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "labels" {
  description = "Метки для всех ресурсов"
  type        = map(string)
  default = {
    project    = "air-quality-monitoring"
    created_by = "terraform"
  }
}

variable "openaq_api_endpoint" {
  description = "Базовый URL для OpenAQ API"
  type        = string
  default     = "https://api.openaq.org/v2"
}

variable "dbt_threads" {
  description = "Количество потоков для dbt"
  type        = number
  default     = 4
}

variable "kestra_port" {
  description = "Порт для Kestra UI"
  type        = number
  default     = 8080
}

variable "kestra_version" {
  description = "Версия Kestra"
  type        = string
  default     = "0.15.0"
}

variable "kestra_basic_auth_username" {
  description = "Имя пользователя для базовой аутентификации Kestra"
  type        = string
  default     = "admin@kestra.io"
  sensitive   = true
}

variable "kestra_basic_auth_password" {
  description = "Пароль для базовой аутентификации Kestra"
  type        = string
  default     = "kestra"
  sensitive   = true
}

variable "postgres_instance_name" {
  description = "Название экземпляра PostgreSQL"
  type        = string
  default     = "kestradb"
}

variable "postgres_tier" {
  description = "Тип машины для PostgreSQL"
  type        = string
  default     = "db-g1-small"
}

variable "postgres_version" {
  description = "Версия PostgreSQL"
  type        = string
  default     = "POSTGRES_15"
}

variable "postgres_database_name" {
  description = "Название базы данных PostgreSQL"
  type        = string
  default     = "kestra"
}

variable "postgres_user" {
  description = "Имя пользователя PostgreSQL"
  type        = string
  default     = "kestra"
  sensitive   = true
}

variable "postgres_password" {
  description = "Пароль пользователя PostgreSQL"
  type        = string
  default     = "kestra-password" # В реальной среде используйте более безопасный пароль или переменную среды
  sensitive   = true
}
