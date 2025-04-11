FROM ubuntu:22.04

# Установка пакетов
RUN apt-get update && apt-get install -y \
  curl \
  unzip \
  jq \
  python3 \
  python3-pip \
  git \
  wget \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

# Установка Terraform
# https://developer.hashicorp.com/terraform/install?product_intent=terraform
RUN wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
  apt-get update && apt-get install terraform


# Установка Google Cloud SDK
# https://cloud.google.com/sdk/docs/install#deb
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  apt-get update -y && apt-get install google-cloud-cli -y


# RUN curl -sSL https://sdk.cloud.google.com | bash
# ENV PATH $PATH:/root/google-cloud-sdk/bin

# Настройка рабочей директории
WORKDIR /app

# Создание директорий
RUN mkdir -p /app/terraform /app/scripts /app/secrets

# Команда по умолчанию
CMD ["/bin/bash"]
