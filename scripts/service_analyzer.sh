#!/usr/bin/env bash
set -e
set -o pipefail
export ES_HOSTS="http://localhost:9200"
export AMQP_EXCHANGE_NAME="/"
export LOGGING_LEVEL=info
export AMQP_VIRTUAL_HOST="/"
export AMQP_URL="amqp://${RABBITMQ_DEFAULT_USER-rabbitmq}:${RABBITMQ_DEFAULT_PASS-rabbitmq}@rabbitmq:5672"
export ANALYZER_BINARYSTORE_TYPE="filesystem"
# ------------------------------------------------------------------------------
# 1. Install Python 3.11.11 (Compiled From Source)
# ------------------------------------------------------------------------------
PY_VERSION="3.11.11"
PY_TARBALL="Python-${PY_VERSION}.tar.xz"

echo "=== Installing dependencies needed to compile Python ${PY_VERSION} ==="
sudo apt-get update -y
sudo apt-get install -y \
  build-essential \
  libssl-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  wget \
  curl \
  llvm \
  libncurses5-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libffi-dev \
  liblzma-dev

echo "=== Downloading and compiling Python ${PY_VERSION} ==="
if [[ ! -f "${PY_TARBALL}" ]]; then
  wget "https://www.python.org/ftp/python/${PY_VERSION}/${PY_TARBALL}"
fi

tar -xf "${PY_TARBALL}"
cd "Python-${PY_VERSION}"
./configure
make -j"$(nproc)"
sudo make altinstall
cd ..

# ------------------------------------------------------------------------------
# 2. Clone the service-auto-analyzer Repository
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/reportportal/service-auto-analyzer.git"
REPO_DIR="service-auto-analyzer"

echo "=== Cloning repository from ${REPO_URL} ==="
if [[ -d "${REPO_DIR}" ]]; then
  echo "Directory '${REPO_DIR}' already exists. Removing it..."
  rm -rf "${REPO_DIR}"
fi
git clone "${REPO_URL}" "${REPO_DIR}"

cd "${REPO_DIR}"

# ------------------------------------------------------------------------------
# 3. Create and Configure a Virtual Environment for "Analyzer"
# ------------------------------------------------------------------------------
echo "=== Creating Python 3.11 virtual environment at /analyzer ==="
python3.11 -m venv /analyzer

echo "=== Installing dependencies from requirements.txt in /analyzer ==="
/analyzer/bin/pip install --upgrade pip
/analyzer/bin/pip install --no-cache-dir -r requirements.txt

echo "=== Downloading NLTK stopwords in /analyzer ==="
/analyzer/bin/python3.11 -m nltk.downloader -d /usr/share/nltk_data stopwords

echo "=== (Optional) Activate the virtual environment ==="
echo "source /analyzer/bin/activate  # if you want an interactive session"

echo "=== Starting uWSGI for analyzer (in the foreground or background) ==="
/analyzer/bin/uwsgi --ini res/analyzer.ini &
ANALYZER_PID=$!

echo "Analyzer is running with PID $ANALYZER_PID."

# ------------------------------------------------------------------------------
# 4. Create and Configure a Virtual Environment for "Analyzer-Train"
# ------------------------------------------------------------------------------
echo "=== Creating Python 3.11 virtual environment at /analyzer-train ==="
python3.11 -m venv /analyzer-train
export INSTANCE_TASK_TYPE="train"
export UWSGI_WORKERS=1
echo "=== Installing dependencies from requirements.txt in /analyzer-train ==="
/analyzer-train/bin/pip install --no-cache-dir -r requirements.txt

echo "=== Downloading NLTK stopwords in /analyzer-train ==="
/analyzer-train/bin/python3.11 -m nltk.downloader -d /usr/share/nltk_data stopwords

echo "=== (Optional) Activate the virtual environment ==="
echo "source /analyzer-train/bin/activate  # if you want an interactive session"

echo "=== Starting uWSGI for analyzer-train (in the foreground or background) ==="
/analyzer-train/bin/uwsgi --ini res/analyzer-train.ini &
ANALYZER_TRAIN_PID=$!

echo "Analyzer-train is running with PID $ANALYZER_TRAIN_PID."

# ------------------------------------------------------------------------------
# 5. Wrap-Up
# ------------------------------------------------------------------------------
echo
echo "============================================================="
echo "Setup complete!"
echo " - Analyzer running (PID: $ANALYZER_PID)"
echo " - Analyzer-train running (PID: $ANALYZER_TRAIN_PID)"
echo "Logs are printed to the console or log files based on your uWSGI config."
echo "============================================================="
echo
echo "If needed, you can stop each service with 'kill <PID>'."
echo "Remember you can edit res/analyzer.ini or res/analyzer-train.ini"
echo "to change worker counts, ports, or other uWSGI settings."