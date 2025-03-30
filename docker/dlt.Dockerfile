# Базовый образ с Python
FROM python:3.10-slim

# Установка основных зависимостей
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  curl \
  && rm -rf /var/lib/apt/lists/*

# Настройка рабочей директории
WORKDIR /app

# Копирование и установка зависимостей
# COPY ../requirements.txt /app/
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install jupyterlab

# Создание директории для кода
RUN mkdir -p /app/dlt_pipeline

# Рабочий пользователь
RUN useradd -m appuser
RUN chown -R appuser:appuser /app
USER appuser

# Команда по умолчанию (запускаем оболочку)
CMD ["/bin/bash"]
