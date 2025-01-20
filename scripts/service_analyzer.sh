#!/usr/bin/env bash
set -e
set -o pipefail

# ------------------------------------------------------------------------------
# 1. Update and Install Dependencies Needed to Compile Python 3.7.4
# ------------------------------------------------------------------------------
echo "==== [1/7] Updating system and installing dependencies for Python 3.7.4 ===="

# Remove the Erlang Solutions list if it exists (may be irrelevant to Python, but consistent with your original script)
sudo rm -f /etc/apt/sources.list.d/erlang-solutions.list || true

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

# ------------------------------------------------------------------------------
# 2. Download and Compile Python 3.7.4 (Avoiding System Python Overwrite)
# ------------------------------------------------------------------------------
PY_VERSION="3.7.4"
PY_TARBALL="Python-${PY_VERSION}.tar.xz"

echo "==== [2/7] Downloading and compiling Python $PY_VERSION ===="

# Download tarball if it does not exist
if [ ! -f "${PY_TARBALL}" ]; then
  wget "https://www.python.org/ftp/python/${PY_VERSION}/${PY_TARBALL}"
fi

# Extract, configure, compile
tar -xf "${PY_TARBALL}"
cd "Python-${PY_VERSION}"
./configure --enable-optimizations
make -j"$(nproc)"
sudo make altinstall
cd ..

# ------------------------------------------------------------------------------
# 3. Create and Configure a Virtual Environment for /analyzer
# ------------------------------------------------------------------------------
echo "==== [3/7] Creating Python 3.7 virtual environment at /analyzer ===="
python3.7 -m venv /analyzer

echo "==== [4/7] Installing packages from requirements.txt in /analyzer ===="
/analyzer/bin/pip install --no-cache-dir -r requirements.txt

echo "==== [5/7] Downloading NLTK stopwords in /analyzer ===="
/analyzer/bin/python3 -m nltk.downloader -d /usr/share/nltk_data stopwords

echo "==== [6/7] Starting uWSGI for /analyzer in the background ===="
# Adjust the path to res/analyzer.ini if different
nohup /analyzer/bin/uwsgi --ini res/analyzer.ini > analyzer.log 2>&1 &

# ------------------------------------------------------------------------------
# 4. Create and Configure a Virtual Environment for /analyzer-train
# ------------------------------------------------------------------------------
echo "==== [7/7] Creating Python 3.7 virtual environment at /analyzer-train ===="
python3.7 -m venv /analyzer-train

echo "Installing packages from requirements.txt in /analyzer-train"
/analyzer-train/bin/pip install --no-cache-dir -r requirements.txt

echo "Downloading NLTK stopwords in /analyzer-train"
/analyzer-train/bin/python3 -m nltk.downloader -d /usr/share/nltk_data stopwords

echo "Starting uWSGI for /analyzer-train in the background"
nohup /analyzer-train/bin/uwsgi --ini res/analyzer-train.ini > analyzer-train.log 2>&1 &

# ------------------------------------------------------------------------------
# Final Information
# ------------------------------------------------------------------------------
echo "-------------------------------------------------------------"
echo "Setup complete!"
echo "uWSGI for Analyzer and Analyzer-Train is running in the background."
echo "-------------------------------------------------------------"