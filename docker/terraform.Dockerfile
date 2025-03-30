# Используем хэшикорп Terraform образ
FROM hashicorp/terraform:1.11

# Установка зависимостей
RUN apk add --no-cache \
  bash \
  curl \
  jq \
  python3 \
  py3-pip

# Установка Google Cloud SDK
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz && \
  tar -xf google-cloud-cli-linux-x86_64.tar.gz && \
  ./google-cloud-sdk/install.sh --quiet && \
  rm google-cloud-cli-linux-x86_64.tar.gz

RUN chmod "+x" ./google-cloud-sdk/path.bash.inc && \
  ./google-cloud-sdk/path.bash.inc

# Настройка рабочей директории
WORKDIR /app
#
# Создание директорий для Terraform кода и секретов
RUN mkdir -p /app/terraform /app/scripts /app/secrets

# Команда по умолчанию (запускаем оболочку)
ENTRYPOINT ["/bin/bash"]
