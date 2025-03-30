output "data_lake_bucket" {
  description = "GCS bucket для Data Lake"
  value       = google_storage_bucket.data_lake_bucket.name
}

output "kestra_storage_bucket" {
  description = "GCS bucket для хранилища Kestra"
  value       = google_storage_bucket.kestra_storage_bucket.name
}

output "bigquery_dataset" {
  description = "BigQuery dataset"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "kestra_vm_ip" {
  description = "IP-адрес Kestra VM"
  value       = google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip
}

output "kestra_ui_url" {
  description = "URL для доступа к Kestra UI"
  value       = "http://${google_compute_instance.kestra_vm.network_interface[0].access_config[0].nat_ip}:${var.kestra_port}"
}

output "kestra_ui_login" {
  description = "Логин для доступа к Kestra UI"
  value       = var.kestra_basic_auth_username
}

output "postgres_instance" {
  description = "Название инстанса PostgreSQL"
  value       = google_sql_database_instance.postgres.name
}

output "postgres_private_ip" {
  description = "Приватный IP PostgreSQL"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "postgres_database" {
  description = "Название базы данных PostgreSQL"
  value       = google_sql_database.kestra_db.name
}

output "postgres_user" {
  description = "Имя пользователя PostgreSQL"
  value       = google_sql_user.kestra_user.name
}

output "service_account_email" {
  description = "Email сервисного аккаунта"
  value       = google_service_account.sa.email
}

output "project_id" {
  description = "ID проекта GCP"
  value       = var.project_id
}

output "region" {
  description = "Регион GCP"
  value       = var.region
}

output "environment" {
  description = "Среда развертывания"
  value       = var.environment
}

output "vpc_network" {
  description = "Название VPC"
  value       = google_compute_network.vpc.name
}

output "subnet" {
  description = "Название подсети"
  value       = google_compute_subnetwork.subnet.name
}
