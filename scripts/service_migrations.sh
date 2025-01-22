#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e
# Treat the pipeline as failed if any command within it fails
set -o pipefail

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
MIGRATIONS_VERSION="5.13.0"
RP_POSTGRES_USER="rpuser"
RP_POSTGRES_DB="reportportal"
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_PASSWORD="rppass"

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
export DATASTORE_TYPE="filesystem" # Type of storage

# ------------------------------------------------------------------------------
# 1. Prepare Automatic Database Authentication
# ------------------------------------------------------------------------------
PGPASS_FILE="$HOME/.pgpass"
echo "Configuring automatic authentication in $PGPASS_FILE..."
cat <<EOF > "$PGPASS_FILE"
${POSTGRES_HOST}:${POSTGRES_PORT}:${RP_POSTGRES_DB}:${RP_POSTGRES_USER}:${POSTGRES_PASSWORD}
EOF
chmod 600 "$PGPASS_FILE"

# ------------------------------------------------------------------------------
# 2. Download and Unzip the Migrations Project
# ------------------------------------------------------------------------------
echo "Downloading the migrations project (version $MIGRATIONS_VERSION)..."
sudo wget "https://github.com/reportportal/migrations/archive/refs/tags/${MIGRATIONS_VERSION}.zip" -O "migrations_${MIGRATIONS_VERSION}.zip"

echo "Unzipping the migrations project..."
sudo unzip "migrations_${MIGRATIONS_VERSION}.zip"
sudo mv "migrations-${MIGRATIONS_VERSION}" migrations
sudo rm -f "migrations_${MIGRATIONS_VERSION}.zip"

# ------------------------------------------------------------------------------
# 3. Run the Migrations
# ------------------------------------------------------------------------------
echo "Running migrations..."
for FILE in $(ls migrations/migrations/*.up.sql | sort -V); do
  echo "Applying migration: $FILE"
  psql -h "$POSTGRES_HOST" \
       -p "$POSTGRES_PORT" \
       -U "$RP_POSTGRES_USER" \
       -d "$RP_POSTGRES_DB" \
       -a -f "$FILE"
done

# ------------------------------------------------------------------------------
# 4. Clean Up
# ------------------------------------------------------------------------------
echo "Removing .pgpass file for security..."
rm -f "$PGPASS_FILE"

echo "Removing migrations scripts folder..."
rm -rf ./migrations/

echo "Migrations completed successfully."