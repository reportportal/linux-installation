#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
# Consider the pipeline as failed if any command within fails
set -o pipefail

# --------------------------------------------------------
# Variables
# --------------------------------------------------------
MAVEN_REPO="https://repo1.maven.org/maven2/com/epam/reportportal"
API_VERSION="5.13.0"
INSTALL_DIR="/opt/reportportal"
JAR_NAME="service-api.jar"

# --------------------------------------------------------
# Java Options
# --------------------------------------------------------
export SERVICE_API_JAVA_OPTS="-Xmx1g -XX:+UseG1GC -XX:InitiatingHeapOccupancyPercent=70 -Djava.security.egd=file:/dev/./urandom"

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

# --------------------------------------------------------
# Datastore Configuration
# --------------------------------------------------------
export DATASTORE_TYPE="filesystem"  # Type of storage

# --------------------------------------------------------
# Additional Environment Variables
# --------------------------------------------------------
export POSTGRES_DB="reportportal"
export RP_ENCRYPTION_KEY="YourStrongEncryptionKey"   # Encryption key
export RP_JOBS_BASEURL="http://localhost:8686"       # Jobs service base URL

# --------------------------------------------------------
# Job Configuration
# --------------------------------------------------------
export COM_TA_REPORTPORTAL_JOB_INTERRUPT_BROKEN_LAUNCHES_CRON="PT1H"    # Cron for interrupting broken launches
export COM_TA_REPORTPORTAL_JOB_LOAD_PLUGINS_CRON="PT10S"               # Cron for loading plugins
export COM_TA_REPORTPORTAL_JOB_CLEAN_OUTDATED_PLUGINS_CRON="PT10S"     # Cron for cleaning up outdated plugins

# --------------------------------------------------------
# Pattern Analysis Configuration
# --------------------------------------------------------
export RP_ENVIRONMENT_VARIABLE_PATTERN_ANALYSIS_BATCH_SIZE="100"       # Batch size for pattern analysis
export RP_ENVIRONMENT_VARIABLE_PATTERN_ANALYSIS_PREFETCH_COUNT="1"     # Prefetch count for pattern analysis
export RP_ENVIRONMENT_VARIABLE_PATTERN_ANALYSIS_CONSUMERS_COUNT="1"    # Number of consumers for pattern analysis

# --------------------------------------------------------
# Reporting Configuration
# --------------------------------------------------------
export REPORTING_QUEUES_COUNT="10"                 # Number of reporting queues
export REPORTING_CONSUMER_PREFETCHCOUNT="10"       # Prefetch for reporting consumers
export REPORTING_PARKINGLOT_TTL_DAYS="7"           # TTL in days for parking lot

# --------------------------------------------------------
# Script Execution
# --------------------------------------------------------

# Create the installation directory if it doesn't exist and adjust permissions
sudo mkdir -p "$INSTALL_DIR"
sudo chown -R "$USER:$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# Download the service API JAR
echo "Downloading service-api-$API_VERSION-exec.jar..."
curl -L "$MAVEN_REPO/service-api/$API_VERSION/service-api-$API_VERSION-exec.jar" -o "$JAR_NAME"

# Verify the download
if [[ ! -f "$JAR_NAME" ]]; then
  echo "Error: Failed to download $JAR_NAME from $MAVEN_REPO"
  exit 1
fi

# Run the service API in the background
echo "Starting ReportPortal API service..."
nohup java $SERVICE_API_JAVA_OPTS -jar "$JAR_NAME" > service-api.log 2>&1 &

echo "ReportPortal API service version $API_VERSION has been started."
echo "Logs are available at: $INSTALL_DIR/service-api.log"
