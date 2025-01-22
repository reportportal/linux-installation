#!/bin/bash

# Exit immediately on any command failure and fail on pipeline errors
set -e
set -o pipefail

# --------------------------------------------------------------------------
# General Variables
OPENSEARCH_VERSION="2.18.0"
TRAEFIK_VERSION="v2.11.15"
DATASTORE_TYPE="filesystem" #Replace with your datastore type

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

# --------------------------------------------------------------------------
# Datastore Configuration
# --------------------------------------------------------------------------
export DATASTORE_TYPE="filesystem"  # Type of storage

# --------------------------------------------------------------------------
# 1. Update System and Install Common Dependencies
# --------------------------------------------------------------------------
echo "Updating repositories and installing common dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl wget gnupg apt-transport-https software-properties-common unzip openjdk-21-jdk golang-go
echo "System updated and common dependencies installed."

# --------------------------------------------------------------------------
# 2. Install and Configure PostgreSQL
# --------------------------------------------------------------------------
echo "Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "Configuring PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';
CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;
ALTER USER $POSTGRES_USER WITH SUPERUSER;
EOF
echo "PostgreSQL installation and configuration complete."

# --------------------------------------------------------------------------
# 3. Install and Configure RabbitMQ 3.12 with Official Repositories
# --------------------------------------------------------------------------
echo "Installing RabbitMQ 3.12.x (and Erlang 25/26) from official Team RabbitMQ repos..."

# (A) Detect or assume OS codename; fallback if it's not recognized by RabbitMQ
OS_CODENAME="$(lsb_release -sc 2>/dev/null || echo 'jammy')"

# Common codenames: jammy (Ubuntu 22.04), focal (20.04), bionic (18.04),
# bullseye (Debian 11), bookworm (Debian 12), etc.
SUPPORTED_CODENAMES=("jammy" "focal" "bionic" "bullseye" "bookworm" \
                     "kinetic" "lunar" "mantic")

if [[ ! " ${SUPPORTED_CODENAMES[@]} " =~ " ${OS_CODENAME} " ]]; then
  echo "Detected codename '${OS_CODENAME}' is not in the supported list. Falling back to 'jammy'..."
  OS_CODENAME="jammy"
fi

echo "Using codename: $OS_CODENAME"

# (B) Install prerequisites
sudo apt-get install -y gnupg curl

# (C) Import the main signing key
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
  | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null

# (D) Import the Erlang repository GPG key (cloudsmith mirror)
curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key" \
  | sudo gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg > /dev/null

# (E) Import the RabbitMQ server repository GPG key (cloudsmith mirror)
curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key" \
  | sudo gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg > /dev/null

# (F) Create /etc/apt/sources.list.d/rabbitmq.list, referencing official ppa1 and ppa2 mirrors
# Replace 'noble' with our $OS_CODENAME
sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP 25/26
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $OS_CODENAME main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $OS_CODENAME main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $OS_CODENAME main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $OS_CODENAME main

## Provides RabbitMQ server
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu $OS_CODENAME main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu $OS_CODENAME main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu $OS_CODENAME main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu $OS_CODENAME main
EOF

# (G) Update apt repositories
sudo apt-get update -y

# (H) Install Erlang packages (all recommended ones) + RabbitMQ server
sudo apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl \
                        rabbitmq-server

# Enable & start the server
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

echo "Configuring RabbitMQ..."
sudo rabbitmqctl add_user admin <your_strong_password>
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

sudo rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASSWORD"
sudo rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
sudo rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*"

# Enable commonly used plugins
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmq-plugins enable rabbitmq_shovel rabbitmq_shovel_management
sudo rabbitmq-plugins enable rabbitmq_consistent_hash_exchange

sudo systemctl restart rabbitmq-server
echo "RabbitMQ 3.12.x (with Erlang 25/26) installation and configuration complete."

# --------------------------------------------------------------------------
# 4. Install and Configure OpenSearch
# --------------------------------------------------------------------------
echo "Installing OpenSearch..."
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/opensearch-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list

sudo apt-get update
export OPENSEARCH_JAVA_OPTS="-Xms512m -Xmx512m"
export DISABLE_INSTALL_DEMO_CONFIG="true"
sudo OPENSEARCH_INITIAL_ADMIN_PASSWORD=<your_strong_password> apt-get install -y opensearch

# Disable SSL for HTTP by modifying the configuration
sudo sed -i 's/plugins.security.ssl.http.enabled: true/plugins.security.ssl.http.enabled: false/' /etc/opensearch/opensearch.yml

sudo systemctl enable opensearch
sudo systemctl start opensearch
echo "OpenSearch installation and configuration complete."

# --------------------------------------------------------------------------
# 5. Install and Configure Traefik
# --------------------------------------------------------------------------
echo "Installing Traefik..."
wget "https://github.com/traefik/traefik/releases/download/$TRAEFIK_VERSION/traefik_v2.11.15_linux_amd64.tar.gz"
tar -xzf "traefik_v2.11.15_linux_amd64.tar.gz"
sudo mv traefik /usr/local/bin/

# Create Traefik configuration directory
sudo mkdir -p /etc/traefik

# --- Download Traefik config files from GitHub ---
echo "Downloading Traefik configuration files from GitHub..."
wget -O /etc/traefik/traefik.yml \
  https://raw.githubusercontent.com/reportportal/linux-installation/main/data/traefik.yml

wget -O /etc/traefik/dynamic_conf.yml \
  https://raw.githubusercontent.com/reportportal/linux-installation/main/data/dynamic_conf.yml

# Create Traefik systemd service
sudo tee /etc/systemd/system/traefik.service <<EOF
[Unit]
Description=Traefik
Documentation=https://doc.traefik.io/traefik/
After=network.target

[Service]
ExecStart=/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable traefik
sudo systemctl start traefik
echo "Traefik installation and configuration complete."

# --------------------------------------------------------------------------
# 6. Install Go (Optional Step)
# --------------------------------------------------------------------------
echo "Installing Go..."
wget https://go.dev/dl/go1.22.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "Go installation complete."

# --------------------------------------------------------------------------
# 7. (Optional) MinIO Installation (Commented Out)
# --------------------------------------------------------------------------
#: "
#echo "Installing MinIO..."
#wget https://dl.min.io/server/minio/release/linux-amd64/minio -O minio
#sudo mv minio /usr/local/bin/
#sudo chmod +x /usr/local/bin/minio

# Create data directory for MinIO
#sudo mkdir -p /data/minio
#sudo chown -R $USER:$USER /data/minio

# Create MinIO service file
#sudo tee /etc/systemd/system/minio.service <<EOF
#[Unit]
#Description=MinIO
#Documentation=https://docs.min.io
#Wants=network-online.target
#After=network-online.target
#
#[Service]
#ExecStart=/usr/local/bin/minio server /data/minio \
#          --console-address ":9001" \
#          --address ":9000"
#Environment="MINIO_ROOT_USER=$DATASTORE_ACCESSKEY"
#Environment="MINIO_ROOT_PASSWORD=$DATASTORE_SECRETKEY"
#Restart=always
#User=root
#Group=root
#
#[Install]
#WantedBy=multi-user.target
#EOF
#
#sudo systemctl daemon-reload
#sudo systemctl enable minio
#sudo systemctl start minio
#
#echo "MinIO installation and configuration complete."
#"

# --------------------------------------------------------------------------
# Finalization
# --------------------------------------------------------------------------
echo "All services have been installed and configured successfully."

# --------------------------------------------------------------------------
# Clean Up Unnecessary Files
# --------------------------------------------------------------------------
echo "Removing unnecessary downloaded files..."
rm -f \
  CHANGELOG.md \
  LICENSE.md \
  go1.22.6.linux-amd64.tar.gz \
  traefik_v2.11.15_linux_amd64.tar.gz

echo "Removed files: CHANGELOG.md, LICENSE.md, go1.22.6.linux-amd64.tar.gz, traefik_v2.11.15_linux_amd64.tar.gz."
