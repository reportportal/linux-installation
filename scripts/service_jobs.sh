#!/bin/bash

# Exit immediately on any command failure
set -e
# Treat the pipeline as failed if any command within it fails
set -o pipefail

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
MAVEN_REPO="https://repo1.maven.org/maven2/com/epam/reportportal"
JOBS_VERSION="5.13.0"
INSTALL_DIR="/opt/reportportal"
JAR_NAME="service-jobs.jar"

# ------------------------------------------------------------------------------
# Database Configuration
# ------------------------------------------------------------------------------
export RP_DB_HOST="${POSTGRES_HOST-localhost}"   # Database server host
export RP_DB_PORT="${POSTGRES_PORT-5432}"        # Database server port
export RP_DB_USER="${POSTGRES_USER-rpuser}"      # Database user
export RP_DB_PASS="${POSTGRES_PASSWORD-rppass}"  # Database password
export RP_DB_NAME="${POSTGRES_DB-reportportal}"  # Database name

# ------------------------------------------------------------------------------
# RabbitMQ (AMQP) Configuration
# ------------------------------------------------------------------------------
export RP_AMQP_HOST="${RABBITMQ_HOST-localhost}"             # RabbitMQ server host
export RP_AMQP_PORT="${RABBITMQ_PORT-5672}"                  # RabbitMQ main port
export RP_AMQP_APIPORT="${RABBITMQ_API_PORT-15672}"          # RabbitMQ API port
export RP_AMQP_USER="${RABBITMQ_DEFAULT_USER-rabbitmq}"      # RabbitMQ user
export RP_AMQP_PASS="${RABBITMQ_DEFAULT_PASS-rabbitmq}"      # RabbitMQ password
export RP_AMQP_APIUSER="${RABBITMQ_DEFAULT_USER-rabbitmq}"   # RabbitMQ API user
export RP_AMQP_APIPASS="${RABBITMQ_DEFAULT_PASS-rabbitmq}"   # RabbitMQ API password
export RP_AMQP_ANALYZER_VHOST="/"                            # RabbitMQ Analyzer virtual host

# ------------------------------------------------------------------------------
# Datastore Configuration
# ------------------------------------------------------------------------------
export DATASTORE_TYPE="filesystem"  # Type of storage

# ------------------------------------------------------------------------------
# Java Options
# ------------------------------------------------------------------------------
export SERVICE_JOBS_JAVA_OPTS="\
-Djava.security.egd=file:/dev/./urandom \
-XX:+UseG1GC \
-XX:+UseStringDeduplication \
-XX:G1ReservePercent=20 \
-XX:InitiatingHeapOccupancyPercent=60 \
-XX:MaxRAMPercentage=70.0 \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:HeapDumpPath=/tmp"

# ------------------------------------------------------------------------------
# 1. Create the Installation Directory
# ------------------------------------------------------------------------------
sudo mkdir -p "$INSTALL_DIR"
sudo chown -R "$USER:$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# ------------------------------------------------------------------------------
# 2. Download the Service Jobs JAR
# ------------------------------------------------------------------------------
echo "Downloading service-jobs-$JOBS_VERSION-exec.jar..."
curl -L "$MAVEN_REPO/service-jobs/$JOBS_VERSION/service-jobs-$JOBS_VERSION-exec.jar" -o "$JAR_NAME"

# Verify the download
if [[ ! -f "$JAR_NAME" ]]; then
  echo "Error: Failed to download $JAR_NAME from $MAVEN_REPO"
  exit 1
fi

# ------------------------------------------------------------------------------
# 3. Set Environment Variables Specific to Jobs Execution
# ------------------------------------------------------------------------------
export RP_AMQP_ANALYZER_VHOST="/"

export RP_ENVIRONMENT_VARIABLE_CLEAN_ATTACHMENT_CRON="0 0 */24 * * *"
export RP_ENVIRONMENT_VARIABLE_CLEAN_LOG_CRON="0 0 */24 * * *"
export RP_ENVIRONMENT_VARIABLE_CLEAN_LAUNCH_CRON="0 0 */24 * * *"
export RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CRON="0 0 */24 * * *"
export RP_ENVIRONMENT_VARIABLE_STORAGE_PROJECT_CRON="0 */5 * * * *"
export RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_CRON="0 0 */24 * * *"    # Removed extra leading space
export RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_RETENTIONPERIOD="365"
export RP_ENVIRONMENT_VARIABLE_NOTIFICATION_EXPIREDUSER_CRON="0 0 */24 * * *"
export RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_RETENTIONPERIOD="365"
export RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_CRON="0 30 05 * * *"
export RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CHUNKSIZE="20000"
export RP_PROCESSING_LOG_MAXBATCHSIZE="2000"
export RP_PROCESSING_LOG_MAXBATCHTIMEOUT="6000"
export RP_AMQP_MAXLOGCONSUMER="1"

# ------------------------------------------------------------------------------
# 4. Launch the Service
# ------------------------------------------------------------------------------
echo "Starting ReportPortal Jobs service..."
nohup java $SERVICE_JOBS_JAVA_OPTS -jar "$JAR_NAME" > service-jobs.log 2>&1 &

echo "ReportPortal JOBS service version $JOBS_VERSION has been started."
echo "Logs are available at: $INSTALL_DIR/service-jobs.log"