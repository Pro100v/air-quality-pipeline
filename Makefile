.PHONY: help setup init-terraform apply-terraform destroy-terraform run-kestra run-dlt-pipeline run-dbt clean all install-terraform install-gcloud install-dlt install-kestra install-dbt docker-build docker-up docker-down docker-logs docker-exec-dlt docker-exec-dbt docker-exec-terraform docker-init-gcloud

# Переменные
PYTHON := python3
PIP := $(PYTHON) -m pip
TERRAFORM_VERSION := 1.6.0
KESTRA_VERSION := 0.15.0
TERRAFORM_DIR := terraform
DBT_DIR := dbt_models
DLT_DIR := dlt_pipeline
DOCKER_COMPOSE := docker compose

# Помощь по командам
help:
	@echo "Доступные команды:"
	@echo "  make help                - Показать список доступных команд"
	@echo "  make setup               - Настроить окружение для проекта"
	@echo "  make init-terraform      - Инициализировать Terraform"
	@echo "  make apply-terraform     - Применить конфигурацию Terraform"
	@echo "  make destroy-terraform   - Удалить инфраструктуру, созданную Terraform"
	@echo "  make run-kestra          - Запустить сервер Kestra"
	@echo "  make run-dlt-pipeline    - Запустить dlt pipeline"
	@echo "  make run-dbt             - Запустить dbt модели"
	@echo "  make clean               - Очистить временные файлы"
	@echo "  make all                 - Запустить полный пайплайн (setup, terraform, dlt, dbt)"
	@echo ""
	@echo "Docker команды:"
	@echo "  make docker-build        - Собрать Docker образы"
	@echo "  make docker-up           - Запустить все Docker контейнеры"
	@echo "  make docker-down         - Остановить все Docker контейнеры"
	@echo "  make docker-logs         - Показать логи Docker контейнеров"
	@echo "  make docker-exec-dlt     - Войти в контейнер dltHub"
	@echo "  make docker-exec-dbt     - Войти в контейнер dbt"
	@echo "  make docker-exec-terraform - Войти в контейнер Terraform"
	@echo "  make docker-init-gcloud  - Инициализировать Google Cloud SDK в контейнере Terraform"
	@echo "  make docker-run-dlt      - Запустить dlt pipeline в контейнере"
	@echo "  make docker-run-dbt      - Запустить dbt модели в контейнере"

# Настройка окружения
setup: install-gcloud install-terraform install-dlt install-dbt install-kestra
	@echo "Установка Python зависимостей..."
	$(PIP) install -r requirements.txt
	@echo "Окружение настроено!"

# Установка Terraform
install-terraform:
	@echo "Проверка наличия Terraform..."
	@if command -v terraform >/dev/null 2>&1; then \
		echo "Terraform уже установлен"; \
	else \
		echo "Установка Terraform $(TERRAFORM_VERSION)..."; \
		curl -fsSL https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip -o terraform.zip; \
		unzip terraform.zip; \
		sudo mv terraform /usr/local/bin/; \
		rm terraform.zip; \
		echo "Terraform установлен!"; \
	fi

# Установка Google Cloud SDK
install-gcloud:
	@echo "Проверка наличия gcloud..."
	@if command -v gcloud >/dev/null 2>&1; then \
		echo "Google Cloud SDK уже установлен"; \
	else \
		echo "Установка Google Cloud SDK..."; \
		curl https://sdk.cloud.google.com > install.sh; \
		bash install.sh --disable-prompts; \
		rm install.sh; \
		echo "Google Cloud SDK установлен!"; \
	fi

# Установка dlt
install-dlt:
	@echo "Установка dlt..."
	$(PIP) install dlt
	@echo "dlt установлен!"

# Установка dbt
install-dbt:
	@echo "Установка dbt..."
	$(PIP) install dbt-core dbt-bigquery
	@echo "dbt установлен!"

# Установка Kestra
install-kestra:
	@echo "Проверка наличия Kestra..."
	@if [ -f "kestra/kestra-$(KESTRA_VERSION).jar" ]; then \
		echo "Kestra уже установлена"; \
	else \
		echo "Установка Kestra..."; \
		mkdir -p kestra; \
		curl -L https://github.com/kestra-io/kestra/releases/download/v$(KESTRA_VERSION)/kestra-$(KESTRA_VERSION).jar -o kestra/kestra-$(KESTRA_VERSION).jar; \
		echo "Kestra установлена!"; \
	fi

# Инициализация Terraform
init-terraform:
	@echo "Инициализация Terraform..."
	cd $(TERRAFORM_DIR) && terraform init
	@echo "Terraform инициализирован!"

# Применение Terraform конфигурации
apply-terraform:
	@echo "Применение конфигурации Terraform..."
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve
	@echo "Инфраструктура развернута!"

# Удаление инфраструктуры
destroy-terraform:
	@echo "Удаление инфраструктуры..."
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve
	@echo "Инфраструктура удалена!"

# Запуск Kestra
run-kestra:
	@echo "Запуск Kestra..."
	java -jar kestra/kestra-$(KESTRA_VERSION).jar server standalone

# Запуск dlt pipeline
run-dlt-pipeline:
	@echo "Запуск dlt pipeline..."
	cd $(DLT_DIR) && $(PYTHON) openaq_pipeline.py
	@echo "dlt pipeline выполнен!"

# Запуск dbt моделей
run-dbt:
	@echo "Запуск dbt моделей..."
	cd $(DBT_DIR) && dbt run
	@echo "dbt модели созданы!"

# Очистка временных файлов
clean:
	@echo "Очистка временных файлов..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name "*.tfstate*" -exec rm -f {} +
	find . -type f -name ".terraform.lock.hcl" -exec rm -f {} +
	find . -type f -name "*.log" -exec rm -f {} +
	@echo "Временные файлы удалены!"

# Полный пайплайн
all: setup init-terraform apply-terraform run-dlt-pipeline run-dbt
	@echo "Полный пайплайн запущен!"

# Docker команды
docker-build:
	@echo "Сборка Docker образов..."
	$(DOCKER_COMPOSE) build
	@echo "Docker образы собраны!"

docker-up:
	@echo "Запуск Docker контейнеров..."
	$(DOCKER_COMPOSE) up -d
	@echo "Docker контейнеры запущены!"
	@echo "Kestra UI доступен по адресу: http://localhost:8080"
	@echo "dbt Docs доступны по адресу: http://localhost:8580"

docker-down:
	@echo "Остановка Docker контейнеров..."
	$(DOCKER_COMPOSE) down
	@echo "Docker контейнеры остановлены!"

docker-logs:
	@echo "Логи Docker контейнеров..."
	$(DOCKER_COMPOSE) logs -f

docker-exec-dlt:
	@echo "Вход в контейнер dltHub..."
	$(DOCKER_COMPOSE) exec dlt-dev bash

docker-exec-dbt:
	@echo "Вход в контейнер dbt..."
	$(DOCKER_COMPOSE) exec dbt-dev bash

docker-exec-terraform:
	@echo "Вход в контейнер Terraform..."
	$(DOCKER_COMPOSE) exec terraform-dev bash

docker-init-gcloud:
	@echo "Инициализация Google Cloud SDK в контейнере Terraform..."
	$(DOCKER_COMPOSE) exec terraform-dev /app/scripts/init-gcloud.sh
	@echo "Google Cloud SDK инициализирован!"

docker-run-dlt:
	@echo "Запуск dlt pipeline в контейнере..."
	$(DOCKER_COMPOSE) exec dlt-dev python /app/dlt_pipeline/openaq_pipeline.py
	@echo "dlt pipeline запущен в контейнере!"

docker-run-dbt:
	@echo "Запуск dbt моделей в контейнере..."
	$(DOCKER_COMPOSE) exec dbt-dev bash -c "cd /app/dbt_models && dbt run --profiles-dir=."
	@echo "dbt модели созданы в контейнере!"

# Запуск всего пайплайна в Docker
docker-all: docker-build docker-up docker-init-gcloud docker-run-dlt docker-run-dbt
	@echo "Полный пайплайн в Docker запущен!"
