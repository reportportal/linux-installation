#!/usr/bin/env bash

# Exit on any command failure
set -e
# Fail on pipeline errors
set -o pipefail

# ------------------------------------------------------------------------------
# 1. Define Common Environment Variables
# ------------------------------------------------------------------------------
# Adjust these to match your environment (e.g., custom host, user, password).
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_USER="rpuser"
export POSTGRES_PASSWORD="rppass"
export POSTGRES_DB="reportportal"

export RABBITMQ_HOST="localhost"
export RABBITMQ_PORT="5672"
export RABBITMQ_API_PORT="15672"
export RABBITMQ_DEFAULT_USER="rabbitmq"
export RABBITMQ_DEFAULT_PASS="rabbitmq"

# ------------------------------------------------------------------------------
# 2. Download the 'scripts' Folder from GitHub
# ------------------------------------------------------------------------------
BRANCH_NAME="EPMRPP-66074"
SCRIPTS_URL="https://github.com/reportportal/linux-installation/archive/refs/heads/${BRANCH_NAME}.zip"
ZIP_FILE="linux-installation-${BRANCH_NAME}.zip"

echo "Downloading scripts from: ${SCRIPTS_URL}"
curl -L "${SCRIPTS_URL}" -o "${ZIP_FILE}"

echo "Unzipping ${ZIP_FILE}..."
unzip -q "${ZIP_FILE}"
SCRIPTS_DIR="linux-installation-${BRANCH_NAME}/update-linux-guide/scripts"

echo "Scripts directory: ${SCRIPTS_DIR}"
if [[ ! -d "${SCRIPTS_DIR}" ]]; then
  echo "Error: Cannot find directory '${SCRIPTS_DIR}' after unzipping."
  exit 1
fi

# Make the scripts executable
chmod +x "${SCRIPTS_DIR}"/*.sh

# ------------------------------------------------------------------------------
# 3. Execute Scripts in Required Order
# ------------------------------------------------------------------------------
cd "${SCRIPTS_DIR}"

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

echo "6) service_index.sh"
./service_index.sh

echo "7) service_analyzer.sh"
./service_analyzer.sh

echo "8) service_ui.sh"
./service_ui.sh

cd -
# Cleanup optional if you like
# rm -rf "linux-installation-${BRANCH_NAME}" "${ZIP_FILE}"

# ------------------------------------------------------------------------------
# Final Message
# ------------------------------------------------------------------------------
echo "All scripts have been executed successfully in the specified order."
echo "Installation and setup complete."