#!/usr/bin/env bash
set -e
set -o pipefail

# ------------------------------------------------------------------------------
# 1. Define Common Environment Variables
# ------------------------------------------------------------------------------
# Adjust these as needed for your environment (PostgreSQL, RabbitMQ, etc.).
MAVEN_REPO="https://repo1.maven.org/maven2/com/epam/reportportal"

API_VERSION="5.13.2"
UAT_VERSION="5.13.0"
MIGRATIONS_VERSION="5.13.0"
UI_VERSION="5.12.13"
SERVICE_INDEX_VERSION="5.13.0"
SERVICE_ANALYZER="5.13.1"
SERVICE_JOBS="5.13.0"
SERVICE_INDEX="5.13.0"

SERVICE_API_JAVA_OPTS="-Xmx1g -XX:+UseG1GC -XX:InitiatingHeapOccupancyPercent=70 -Djava.security.egd=file:/dev/./urandom"
SERVICE_UAT_JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -XX:MinRAMPercentage=60.0 -XX:MaxRAMPercentage=90.0 --add-opens=java.base/java.lang=ALL-UNNAMED"
SERVICE_JOBS_JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -XX:+UseG1GC -XX:+UseStringDeduplication -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=60 -XX:MaxRAMPercentage=70.0 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp"

POSTGRES_DB="reportportal"
RP_ENCRYPTION_KEY=<YourStrongEncryptionKey>
RP_JOBS_BASEURL="http://localhost:8686"    

RP_AMQP_HOST=<your_rabbitmq_host>
RP_AMQP_PORT=<your_rabbitmq_port>
RP_AMQP_APIPORT=<your_rabbitmq_api_port>
RP_AMQP_USER=<your_rabbitmq_user>
RP_AMQP_PASS=<your_rabbitmq_password>
RP_AMQP_APIUSER=<your_rabbitmq_api_user>
RP_AMQP_APIPASS=<your_rabbitmq_api_password>
RP_AMQP_ANALYZER_VHOST=<your_analyzer_virtual_host>
RABBITMQ_HOST=<your_rabbitmq_host>
RABBITMQ_PORT=<your_rabbitmq_port>
RABBITMQ_API_PORT=<your_rabbitmq_api_port>
RABBITMQ_DEFAULT_USER=<your_rabbitmq_default_user>
RABBITMQ_DEFAULT_PASS=<your_rabbitmq_default_password>
AMQP_EXCHANGE_NAME=<your_amqp_exchange_name>
AMQP_VIRTUAL_HOST=<your_amqp_virtual_host>
AMQP_URL="amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@${RP_AMQP_HOST}:${RP_AMQP_PORT}${RP_AMQP_ANALYZER_VHOST}"

DATASTORE_TYPE="filesystem" 

ANALYZER_BINARYSTORE_TYPE=<your_analyzer_binarystore_type>
INSTANCE_TASK_TYPE=<your_instance_task_type>
UWSGI_WORKERS=<your_uwsgi_workers_count>

COM_TA_REPORTPORTAL_JOB_INTERRUPT_BROKEN_LAUNCHES_CRON="PT1H"
COM_TA_REPORTPORTAL_JOB_LOAD_PLUGINS_CRON="PT10S"
COM_TA_REPORTPORTAL_JOB_CLEAN_OUTDATED_PLUGINS_CRON="PT10S"
RP_ENVIRONMENT_VARIABLE_CLEAN_ATTACHMENT_CRON="0 0 */24 * * *"
RP_ENVIRONMENT_VARIABLE_CLEAN_LOG_CRON="0 0 */24 * * *"
RP_ENVIRONMENT_VARIABLE_CLEAN_LAUNCH_CRON="0 0 */24 * * *"
RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CRON="0 0 */24 * * *"
RP_ENVIRONMENT_VARIABLE_STORAGE_PROJECT_CRON="0 */5 * * * *"
RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_CRON="0 0 */24 * * *"
RP_ENVIRONMENT_VARIABLE_NOTIFICATION_EXPIREDUSER_CRON="0 0 */24 * * *"
RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_CRON="0 30 05 * * *"
RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_RETENTIONPERIOD="365"
RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CHUNKSIZE="20000"
RP_ENVIRONMENT_VARIABLE_PATTERN_ANALYSIS_BATCH_SIZE="100"
RP_ENVIRONMENT_VARIABLE_PATTERN_ANALYSIS_PREFETCH_COUNT="1"
RP_ENVIRONMENT_VARIABLE_PATTERN_ANALYSIS_CONSUMERS_COUNT="1"

RP_SERVER_PORT=<your_server_port>
RP_JOBS_BASEURL=<your_jobs_base_url>
RP_SESSION_LIVE=<your_session_live_duration>
RP_SAML_SESSION_LIVE=<your_saml_session_live_duration>
DATASTORE_PATH=<your_datastore_path>
NODE_VERSION="20"
PY_VERSION="23.11.11"
LOGGING_LEVEL=<your_logging_level>

# ------------------------------------------------------------------------------
# 2. Clone the Repository from GitHub (Branch: Main)
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/reportportal/linux-installation.git"
BRANCH_NAME="main"
LOCAL_DIR="linux-installation"

echo "Cloning repository from ${REPO_URL} (branch: ${BRANCH_NAME})..."
git clone --branch "${BRANCH_NAME}" --depth 1 "${REPO_URL}" "${LOCAL_DIR}"

# ------------------------------------------------------------------------------
# 3. Execute Scripts in Required Order
# ------------------------------------------------------------------------------
cd "${LOCAL_DIR}/scripts" || {
  echo "Error: Cannot find 'scripts' folder in cloned repo."
  exit 1
}

# Make sure each script is executable
chmod +x ./*.sh

echo "1) install_dependencies.sh"
./install_dependencies.sh

echo "2) service_migrations.sh"
./service_migrations.sh

echo "3) service_api.sh"
./service_api.sh

echo "4) service_uat.sh"
./service_uat.sh

echo "5) service_jobs.sh"
./service_jobs.sh

echo "6) service_ui.sh"
./service_ui.sh

echo "7) service_analyzer.sh"
./service_analyzer.sh

echo "8) service_index.sh"
./service_index.sh

# ------------------------------------------------------------------------------
# Final Message
# ------------------------------------------------------------------------------
cd -
echo "All scripts have been executed successfully in the specified order."
echo "Installation and setup complete."
