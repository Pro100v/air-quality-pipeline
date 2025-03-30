ARG py_version=3.11.2

FROM python:$py_version-slim-bullseye as base

RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  git \
  libpq-dev \
  make \
  openssh-client \
  software-properties-common \
  && apt-get clean \
  && rm -rf \
  /var/lib/apt/lists/* \
  /tmp/* \
  /var/tmp/*

ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir

# Установка dbt-core и dbt-bigquery
RUN python -m pip install --no-cache-dir dbt-core dbt-bigquery

# Создание директории для кода
RUN mkdir -p /app/dbt_models

# Настройка рабочей директории
WORKDIR /app

# Команда по умолчанию
CMD ["/bin/bash"]
