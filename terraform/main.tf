terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.14"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  all_labels = merge(var.labels, {
    environment = var.environment
  })
}

# Создание сервисного аккаунта
resource "google_service_account" "sa" {
  account_id   = var.sa_name
  display_name = "Service Account for Air Quality Data Pipeline"
  description  = "Used for accessing GCS, BigQuery and running the data pipeline"
}

# Назначение ролей для сервисного аккаунта
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "cloudsql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Создание GCS bucket для Data Lake
resource "google_storage_bucket" "data_lake_bucket" {
  name                        = "${var.data_lake_bucket_name}-${var.project_id}"
  location                    = var.region
  force_destroy               = true # Для dev/тестового окружения
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30 # дней
    }
    action {
      type = "Delete"
    }
  }

  labels = local.all_labels
}

# Создание GCS bucket для Kestra
resource "google_storage_bucket" "kestra_storage_bucket" {
  name                        = "${var.kestra_storage_bucket_name}-${var.project_id}"
  location                    = var.region
  force_destroy               = true # Для dev/тестового окружения
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = local.all_labels
}

# Создание подпапок в GCS Data Lake
resource "google_storage_bucket_object" "raw_folder" {
  name    = "raw/"
  content = " " # Это создаст пустой объект
  bucket  = google_storage_bucket.data_lake_bucket.name
}

resource "google_storage_bucket_object" "processed_folder" {
  name    = "processed/"
  content = " "
  bucket  = google_storage_bucket.data_lake_bucket.name
}

# Создание BigQuery dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = var.bigquery_dataset_name
  friendly_name              = "Air Quality Dataset"
  description                = "Dataset for storing air quality measurements"
  location                   = var.bigquery_location
  delete_contents_on_destroy = true # Для dev/тестового окружения

  labels = local.all_labels
}

# Создание VPC для приватного подключения к Cloud SQL
resource "google_compute_network" "vpc" {
  name                    = "kestra-vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "kestra-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Создание приватного IP для Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "kestra-db-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Настройка приватного сервисного соединения
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Создание инстанса PostgreSQL в Cloud SQL
resource "google_sql_database_instance" "postgres" {
  name             = var.postgres_instance_name
  database_version = var.postgres_version
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.postgres_tier
    availability_type = "ZONAL" # Используйте "REGIONAL" для высокой доступности

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    backup_configuration {
      enabled                        = true
      binary_log_enabled             = false
      start_time                     = "02:00"
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
      }
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000" # 1 секунда
    }

    maintenance_window {
      day          = 7 # Воскресенье
      hour         = 2 # 2:00 AM
      update_track = "stable"
    }

    disk_size = 10 # GB
    disk_type = "PD_SSD"

    user_labels = local.all_labels
  }

  deletion_protection = false # Установите true для production
}

# Создание базы данных для Kestra
resource "google_sql_database" "kestra_db" {
  name     = var.postgres_database_name
  instance = google_sql_database_instance.postgres.name
}

# Создание пользователя для Kestra
resource "google_sql_user" "kestra_user" {
  name     = var.postgres_user
  instance = google_sql_database_instance.postgres.name
  password = var.postgres_password
}

# Создание VM для Kestra
resource "google_compute_instance" "kestra_vm" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20 # ГБ
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    
    # Обновление системы
    apt-get update
    apt-get upgrade -y
    
    # Установка необходимых пакетов
    apt-get install -y ca-certificates curl gnupg jq vim unzip python3-pip
    
    # Установка Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Установка Google Cloud SDK
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update
    apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
    
    # Установка Python зависимостей
    pip3 install dlt dbt-core dbt-bigquery
    
    # Создание директории для Kestra
    mkdir -p /opt/kestra
    cd /opt/kestra
    
    # Скачивание docker-compose.yml для Kestra
    curl -o docker-compose.yml \
    https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
    
    # Формирование файла конфигурации Kestra
    cat > /opt/kestra/application.yml <<EOL
kestra:
  server:
    basicAuth:
      enabled: true
      username: "${var.kestra_basic_auth_username}"
      password: "${var.kestra_basic_auth_password}"
  
  storage:
    type: gcs
    gcs:
      bucket: "${google_storage_bucket.kestra_storage_bucket.name}"
      projectId: "${var.project_id}"
      serviceAccount: "\${GOOGLE_SERVICE_ACCOUNT}"

  datasources:
    postgres:
      url: jdbc:postgresql://${google_sql_database_instance.postgres.private_ip_address}:5432/${var.postgres_database_name}
      driverClassName: org.postgresql.Driver
      username: "${var.postgres_user}"
      password: "${var.postgres_password}"
EOL
    
    # Скачивание ключа сервисного аккаунта
    mkdir -p /opt/kestra/secrets
    gcloud iam service-accounts keys create /opt/kestra/secrets/sa-key.json \
      --iam-account=${google_service_account.sa.email}
    
    # Обновление docker-compose.yml для Kestra
    cat > /opt/kestra/docker-compose.yml <<EOL
version: "3.8"

services:
  kestra:
    image: kestra/kestra:latest
    container_name: kestra
    pull_policy: always
    user: "root"
    command: server standalone
    volumes:
      - /opt/kestra/application.yml:/app/application.yml
      - /opt/kestra/secrets:/app/secrets
    ports:
      - "${var.kestra_port}:8080"
      - "8081:8081"
    environment:
      KESTRA_CONFIGURATION: /app/application.yml
      GOOGLE_SERVICE_ACCOUNT: \$\$(cat /app/secrets/sa-key.json)
    restart: unless-stopped
EOL
    
    # Запуск Kestra с Docker Compose
    cd /opt/kestra
    docker compose up -d
  EOF

  tags = ["kestra", "orchestrator"]

  labels = local.all_labels
}

# Создание firewall правила для доступа к Kestra UI
resource "google_compute_firewall" "kestra_firewall" {
  name    = "allow-kestra-ui"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = [var.kestra_port]
  }

  source_ranges = ["0.0.0.0/0"] # В реальном проекте лучше ограничить IP-адресами
  target_tags   = ["kestra"]
}

# Создание BigQuery таблиц (пустых) для сырых данных
resource "google_bigquery_table" "air_quality_raw" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "air_quality_raw"

  schema = <<EOF
[
  {
    "name": "location",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Location of measurement"
  },
  {
    "name": "parameter",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Parameter measured (PM2.5, PM10, etc.)"
  },
  {
    "name": "value",
    "type": "FLOAT",
    "mode": "NULLABLE",
    "description": "Measured value"
  },
  {
    "name": "unit",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Unit of measurement"
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "City name"
  },
  {
    "name": "country",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Country code"
  },
  {
    "name": "coordinates",
    "type": "RECORD",
    "mode": "NULLABLE",
    "description": "Geographical coordinates",
    "fields": [
      {
        "name": "latitude",
        "type": "FLOAT",
        "mode": "NULLABLE"
      },
      {
        "name": "longitude",
        "type": "FLOAT",
        "mode": "NULLABLE"
      }
    ]
  },
  {
    "name": "date_utc",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "Measurement date and time in UTC"
  },
  {
    "name": "date_local",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "Measurement date and time in local timezone"
  },
  {
    "name": "ingestion_timestamp",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "Data ingestion timestamp"
  }
]
EOF

  labels = local.all_labels
}
