#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
# Treat the pipeline as failed if any command within it fails
set -o pipefail

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
MAVEN_REPO="https://repo1.maven.org/maven2/com/epam/reportportal"
UAT_VERSION="5.13.0"
INSTALL_DIR="/opt/reportportal"
JAR_NAME="service-uat.jar"

# ------------------------------------------------------------------------------
# Environment / Java Options
# ------------------------------------------------------------------------------
export SERVICE_UAT_JAVA_OPTS="\
-Djava.security.egd=file:/dev/./urandom \
-XX:MinRAMPercentage=60.0 \
-XX:MaxRAMPercentage=90.0 \
--add-opens=java.base/java.lang=ALL-UNNAMED"

# --------------------------------------------------------------------------
# Database Configuration (ReportPortal)
# --------------------------------------------------------------------------
export RP_DB_HOST="${POSTGRES_HOST-localhost}"      # Database server host
export RP_DB_PORT="${POSTGRES_PORT-5432}"          # Database server port
export RP_DB_USER="${POSTGRES_USER-rpuser}"        # Database user
export RP_DB_PASS="${POSTGRES_PASSWORD-rppass}"    # Database password
export RP_DB_NAME="${POSTGRES_DB-reportportal}"    # Database name

# --------------------------------------------------------------------------
# RabbitMQ (AMQP) Configuration (ReportPortal)
# --------------------------------------------------------------------------
export RP_AMQP_HOST="${RABBITMQ_HOST-localhost}"                   # RabbitMQ server host
export RP_AMQP_PORT="${RABBITMQ_PORT-5672}"                       # RabbitMQ main port
export RP_AMQP_APIPORT="${RABBITMQ_API_PORT-15672}"               # RabbitMQ API port
export RP_AMQP_USER="${RABBITMQ_DEFAULT_USER-rabbitmq}"           # RabbitMQ user
export RP_AMQP_PASS="${RABBITMQ_DEFAULT_PASS-rabbitmq}"           # RabbitMQ password
export RP_AMQP_APIUSER="${RABBITMQ_DEFAULT_USER-rabbitmq}"        # RabbitMQ API user
export RP_AMQP_APIPASS="${RABBITMQ_DEFAULT_PASS-rabbitmq}"        # RabbitMQ API password
export RP_AMQP_ANALYZER_VHOST="/"                                 # Virtual host for RabbitMQ Analyzer

# ------------------------------------------------------------------------------
# Datastore Configuration
# ------------------------------------------------------------------------------
export DATASTORE_TYPE="filesystem"  # Type of storage

# ------------------------------------------------------------------------------
# Script Execution
# ------------------------------------------------------------------------------
# 1. Ensure the installation directory exists and has correct permissions
sudo mkdir -p "$INSTALL_DIR"
sudo chown -R "$USER:$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# 2. Download the service authorization JAR
echo "Downloading service-authorization-$UAT_VERSION-exec.jar..."
curl -L "$MAVEN_REPO/service-authorization/$UAT_VERSION/service-authorization-$UAT_VERSION-exec.jar" -o "$JAR_NAME"

# 3. Verify the download
if [[ ! -f "$JAR_NAME" ]]; then
  echo "Error: Failed to download $JAR_NAME from $MAVEN_REPO"
  exit 1
fi

# 4. Set additional environment variables
export RP_SESSION_LIVE="86400"                          # Regular session duration (in seconds)
export RP_SAML_SESSION_LIVE="4320"                      # SAML session duration (in seconds)
export DATASTORE_PATH="/data/"
export RP_INITIAL_ADMIN_PASSWORD="${RP_INITIAL_ADMIN_PASSWORD:-erebus}"

# 5. Run the UAT (Authentication) Service
echo "Starting ReportPortal Authentication Service..."
nohup java $SERVICE_UAT_JAVA_OPTS -jar "$JAR_NAME" > "service-uat.log" 2>&1 &

echo "ReportPortal Authentication Service version $UAT_VERSION has been started."
echo "Logs are available at: $INSTALL_DIR/service-uat.log"