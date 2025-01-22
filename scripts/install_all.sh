#!/usr/bin/env bash
set -e
set -o pipefail

# ------------------------------------------------------------------------------
# 1. Define Common Environment Variables
# ------------------------------------------------------------------------------
# Adjust these as needed for your environment (PostgreSQL, RabbitMQ, etc.).
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
# 2. Clone the Repository from GitHub (Branch: EPMRPP-66074)
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/reportportal/linux-installation.git"
BRANCH_NAME="EPMRPP-66074/update-linux-guide"
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
