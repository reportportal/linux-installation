#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e
# Treat the pipeline as failed if any command within fails
set -o pipefail

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/reportportal/service-ui.git"
TAG="5.12.2"
NODE_VERSION="20"
PROJECT_DIR="$(pwd)/service-ui"
APP_DIR="$PROJECT_DIR/app"

# You can change these as needed
export RP_SERVER_PORT="8080"
export APP_VERSION="5.13.0"
export NODE_OPTIONS="--max-old-space-size=4096"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Checks if a command exists on the system
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 1. Install Dependencies
# ------------------------------------------------------------------------------
install_dependencies() {
  echo -e "\n--- Installing required dependencies ---"
  if ! command_exists git; then
    sudo apt-get update
    sudo apt-get install -y git
  fi

  if ! command_exists node; then
    echo "Installing Node.js..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash -
    sudo apt-get install -y nodejs
  fi

  if ! command_exists npm; then
    echo "Installing npm..."
    sudo apt-get install -y npm
  fi
}

# ------------------------------------------------------------------------------
# 2. Clone the Repository
# ------------------------------------------------------------------------------
clone_repo() {
  echo -e "\n--- Cloning the repository ---"
  if [ -d "$PROJECT_DIR" ]; then
    echo "Directory $PROJECT_DIR already exists. Removing it..."
    rm -rf "$PROJECT_DIR"
  fi
  git clone "$REPO_URL" "$PROJECT_DIR"
  cd "$PROJECT_DIR"
  git checkout "$TAG"
}

# ------------------------------------------------------------------------------
# 3. Install Project Dependencies
# ------------------------------------------------------------------------------
install_project_dependencies() {
  echo -e "\n--- Installing project dependencies ---"
  if [ ! -d "$APP_DIR" ]; then
    echo "Error: Directory $APP_DIR does not exist. Check the repository structure."
    exit 1
  fi
  cd "$APP_DIR"

  # Clear npm cache to avoid any stale data
  npm cache clean --force

  # Attempt a standard installation
  npm install --legacy-peer-deps --prefer-offline --no-audit --no-fund || {
    echo "Error encountered during npm install. Attempting forced installation..."
    npm install --force
  }
}

# ------------------------------------------------------------------------------
# 4. Setup Environment Variables
# ------------------------------------------------------------------------------
setup_env() {
  echo -e "\n--- Setting up environment variables ---"
  if [ ! -f "$APP_DIR/.env" ]; then
    echo "Creating a basic .env file in $APP_DIR..."
    cat <<EOL > "$APP_DIR/.env"
PROXY_PATH='http://localhost:8080/'
EOL
  fi
  echo "If needed, edit $APP_DIR/.env before continuing."
}

# ------------------------------------------------------------------------------
# 5. Run the Project
# ------------------------------------------------------------------------------
run_project() {
  echo -e "\n--- Starting the project ---"
  cd "$APP_DIR"
  # Runs in the background; logs are stored in ui.log
  nohup npm run dev > ui.log 2>&1 &
  echo "Service-UI is now running in the background. Log file: $APP_DIR/ui.log"
}

# ------------------------------------------------------------------------------
# Main Script Execution
# ------------------------------------------------------------------------------
echo -e "\nStarting setup and launch of ReportPortal Service-UI..."
install_dependencies
clone_repo
install_project_dependencies
setup_env
run_project

echo "Setup and launch completed successfully."