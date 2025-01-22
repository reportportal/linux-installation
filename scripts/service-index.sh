#!/usr/bin/env bash

# index.sh
# Script to install and run "service-index" in the background by cloning
# and building code from the GitHub tag 5.13.0.

set -e
set -o pipefail

# ------------------------------------------------------------------------------
# 1. Configuration: Environment Variables & Paths
# ------------------------------------------------------------------------------
# Final installation directory (where the compiled binary will live)
INSTALL_DIR="/home/ubuntu/service-index"

# Temporary build directory
APP_DIR="/home/ubuntu/tmp/service-index-build"

# Repository URL and tag
: "${REPO_URL:=https://github.com/reportportal/service-index.git}"
: "${REPO_TAG:=5.13.0}"

# Build variables
: "${APP_VERSION:=5.13.0}"
: "${PACKAGE_COMMONS:=github.com/reportportal/commons-go/v5}"
: "${REPO_NAME:=reportportal/service-index}"
: "${BUILD_BRANCH:=v5.13.0}"
: "${BUILD_DATE:=$(date -u +'%Y-%m-%d_%H:%M:%S')}"

# Cross-compilation variables (if needed)
: "${TARGETOS:=linux}"
: "${TARGETARCH:=amd64}"

# Application runtime settings
export RP_SERVER_PORT=9000

# Final binary name
APP_BINARY="app"

# ------------------------------------------------------------------------------
# 2. Prepare the Build Environment
# ------------------------------------------------------------------------------
echo ">>> Creating temporary build directory: ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}"

echo ">>> Cloning repository from ${REPO_URL}, tag: ${REPO_TAG}"
# Force Git not to prompt for credentials if the URL is public
export GIT_TERMINAL_PROMPT=0

git clone --depth 1 --branch "${REPO_TAG}" "${REPO_URL}" "${APP_DIR}" || {
  echo "Error: Failed to clone the repository. Does tag ${REPO_TAG} exist?"
  exit 1
}

cd "${APP_DIR}" || {
  echo "Error: Unable to access directory ${APP_DIR}"
  exit 1
}

# ------------------------------------------------------------------------------
# 3. Compile the Application
# ------------------------------------------------------------------------------
echo ">>> Compiling the application with GOOS=${TARGETOS} GOARCH=${TARGETARCH}"
echo ">>> Build variables:"
echo "    - REPO_NAME:       ${REPO_NAME}"
echo "    - BUILD_BRANCH:    ${BUILD_BRANCH}"
echo "    - BUILD_DATE:      ${BUILD_DATE}"
echo "    - APP_VERSION:     ${APP_VERSION}"
echo "    - PACKAGE_COMMONS: ${PACKAGE_COMMONS}"
echo

CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" go build \
   -ldflags "-extldflags '-static' \
   -X ${PACKAGE_COMMONS}/commons.repo=${REPO_NAME} \
   -X ${PACKAGE_COMMONS}/commons.branch=${BUILD_BRANCH} \
   -X ${PACKAGE_COMMONS}/commons.buildDate=${BUILD_DATE} \
   -X ${PACKAGE_COMMONS}/commons.version=${APP_VERSION}" \
   -o "${APP_BINARY}" .

# Verify the binary was generated
if [[ ! -f "${APP_BINARY}" ]]; then
  echo "Error: The binary '${APP_BINARY}' was not created. Check for compilation errors."
  exit 1
fi

# ------------------------------------------------------------------------------
# 4. Install the Binary on the System
# ------------------------------------------------------------------------------
echo ">>> Creating installation directory: ${INSTALL_DIR}"
rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

echo ">>> Copying compiled binary to the installation directory"
cp "${APP_BINARY}" "${INSTALL_DIR}/"

# Adjust permissions if desired
chgrp -R 0 "${INSTALL_DIR}" || true
chmod -R g=u "${INSTALL_DIR}" || true

# ------------------------------------------------------------------------------
# 5. Cleanup
# ------------------------------------------------------------------------------
echo ">>> Cleaning the temporary build directory"
rm -rf "${APP_DIR}"

# ------------------------------------------------------------------------------
# 6. Run with nohup
# ------------------------------------------------------------------------------
echo ">>> Starting the service in the background using nohup..."

cd "${INSTALL_DIR}" || exit 1
nohup "./${APP_BINARY}" > service-index.log 2>&1 &

echo ">>> The service is now running in the background."
echo ">>> Check '${INSTALL_DIR}/service-index.log' for logs."
echo
echo ">>> Installation and startup completed."
echo
echo "If you want to stop the service, find its PID and run 'kill <PID>'."
echo "For example, you can use:  pgrep -f ${APP_BINARY}"
echo