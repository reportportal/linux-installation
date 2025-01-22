# ReportPortal Linux installation
[![Join Slack chat!](https://reportportal-slack-auto.herokuapp.com/badge.svg)](https://reportportal-slack-auto.herokuapp.com)
[![stackoverflow](https://img.shields.io/badge/reportportal-stackoverflow-orange.svg?style=flat)](http://stackoverflow.com/questions/tagged/reportportal)
[![GitHub contributors](https://img.shields.io/badge/contributors-102-blue.svg)](https://reportportal.io/community)
[![Docker Pulls](https://img.shields.io/docker/pulls/reportportal/service-api.svg?maxAge=25920)](https://hub.docker.com/u/reportportal/)
[![License](https://img.shields.io/badge/license-Apache-brightgreen.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Build with Love](https://img.shields.io/badge/build%20with-❤%EF%B8%8F%E2%80%8D-lightgrey.svg)](http://reportportal.io?style=flat)

## Description

[ReportPortal.io](https://reportportal.io) is a service, that provides increased capabilities to speed up results analysis and reporting through the use of built-in analytic features.

ReportPortal is a great addition to the Continuous Integration and Continuous Testing process.

## Supported OS

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange?style=flat-square)

![RHEL](https://img.shields.io/badge/RHEL-7.9-red?style=flat-square)
![RHEL](https://img.shields.io/badge/RHEL-8.x-red?style=flat-square)
![RHEL](https://img.shields.io/badge/RHEL-9.x-red?style=flat-square)

## Table of contents
* [Report Portal Installation ](#ReportPortal)
* [Description](#Descriprion)
* [Supported OS](#Supported-OS)
* [Required Services](#Required-Services)
    * [PostgreSQL](#PostgreSQL)
    * [RabbitMQ](#RabbitMQ)
    * [OpenSearch](#OpenSearch)
    * [Traefik](#Traefik)
    * [ReportPortal Services](#ReportPortal-Services)
    * [Preparation](#Preparation)
    * [Repositories](#Repositories)
    * [Analyzer](#Analyzer)
    * [Migration](#Migration)
    * [Index](#Index)
    * [API](#API)
    * [UAT](#UAT)
    * [UI](#UI)

## Required Services
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.2-blue?style=flat-square)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-4.0.5-blue?style=flat-square)
![OpenSearch](https://img.shields.io/badge/OpenSearch-2.18.0-blue?style=flat-square)
![Traefik](https://img.shields.io/badge/Traefik-2.11.16-blue?style=flat-square)
![Go](https://img.shields.io/badge/Go-22.6.1-blue?style=flat-square)

### PostgreSQL

How to install PostgreSQL 16 or 17 on [Ubuntu](https://www.postgresql.org/download/linux/ubuntu/) LTS 20.04, 22.04, LTS 24.04 / [Red Hat family](https://www.postgresql.org/download/linux/redhat/) (RHEL, AlmaLinux, etc).

1. After successful installation, you need to prepare the database for ReportPortal services `sudo su - postgres -c "psql"`

```SQL
CREATE DATABASE reportportal; 
CREATE USER <your_rpdbuser> WITH ENCRYPTED PASSWORD '<your_rpdbuser_password>';
GRANT ALL PRIVILEGES ON DATABASE reportportal TO <your_rpdbuser>;
ALTER USER <your_rpdbuser> WITH SUPERUSER;
```

2. Change your PostgreSQL authentication methods. Edit the `pg_hba.conf` file, and change `peer` to `md5` in the following lines:

```python
# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
```
File location:
* Ubuntu: `/etc/postgresql/<PSQL_VERSION>/main/pg_hba.conf`
* RHEL: `/var/lib/pgsql/<PSQL_VERSION>/data/pg_hba.conf`

3. After the changes above, restart the PostgreSQL service 
```bash
sudo systemctl restart postgresql
```

4. Create the ***pgcrypto*** extantion for PostgreSQL `reportportal` database

```bash
psql -U rpuser -d reportportal -c "CREATE EXTENSION pgcrypto;"
```

### RabbitMQ

How to install RabbitMQ 4.0.5 on [Ubuntu](https://www.rabbitmq.com/docs/install-debian#apt-quick-start-cloudsmith) LTS 20.04, 22.04, 24.04 / [Red Hat family](https://www.rabbitmq.com/docs/install-rpm) (RHEL, AlmaLinux, etc.).

1. After installation, enable RabbitMQ web management console:

```bash
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmq-plugins enable rabbitmq_shovel rabbitmq_shovel_management
sudo rabbitmq-plugins enable rabbitmq_consistent_hash_exchange
```

2. Check and provide ownership of RabbitMQ files to the RabbitMQ user:

```bash
sudo chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
```

3. Create an admin user for the RabbitMQ web management console

```bash
sudo rabbitmqctl add_user admin <strong_password>
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

4. Configure user, permissions, and vhost for ReportPortal. Run the following commands in order to configure your RabbitMQ work with ReportPortal. Please determine the name and the password for your ReportPortal Rabbitmq user in advance

```bash
sudo rabbitmqctl add_user <your_rpmquser> <your_rpmquser_password>
sudo rabbitmqctl set_user_tags <your_rpmquser> administrator
sudo rabbitmqctl set_permissions -p / <your_rpmquser> ".*" ".*" ".*"
sudo rabbitmqctl add_vhost analyzer
sudo rabbitmqctl set_permissions -p analyzer <your_rpmquser> ".*" ".*" ".*"
```

5. Restart rabbitmq server to deploy changes
```bash
sudo systemctl restart rabbitmq-server
```
To check RabbitMQ look forward <you_IP>:15672

![RabbitMQ](img/rabbitmq.gif)

### Option 1 (Recomended): OpenSearch

How to install OpenSearch 2.18.0 on [Ubuntu] (https://opensearch.org/docs/latest/install-and-configure/install-opensearch/debian/) LTS 20.04, 22.04, 24.04 / [Red Hat family](https://opensearch.org/docs/latest/install-and-configure/install-opensearch/rpm/) (RHEL, AlmaLinux, etc).
Check for Java requirements in your host according to compatibility (https://opensearch.org/docs/latest/install-and-configure/install-opensearch/index/)
To check OpenSearch use the 

curl -u '<your_opensearch_user>:<your_opensearch_password>' -XGET http://localhost:9200/_cluster/health?pretty (Use https if you're using SSL on your instance).
```json
{
  "cluster_name" : "opensearch",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "discovered_master" : true,
  "discovered_cluster_manager" : true,
  "active_primary_shards" : 6,
  "active_shards" : 6,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 2,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 75.0
}
```

### Option 2: ElasticSearch

How to install ElasticSearch 8.17 on [Ubuntu](https://www.elastic.co/guide/en/OpenSearch/reference/current/deb.html) LTS 20.04, 22.04, 24.04 / [Red Hat family](https://www.elastic.co/guide/en/OpenSearch/reference/current/rpm.html) (RHEL, AlmaLinux, etc). Also you need to install `openjdk-11-jre-headless` and `openjdk-8-jdk`

To check ElasticSearch use the `curl -X GET "localhost:9200/"`. The output will be:

```json
{
    "name" : "reportportal",
    "cluster_name" : "ElasticSearch",
    "cluster_uuid" : "98xfWPnKQNSI1ql7q7y57w",
    "version" : {
        "number" : "7.10.1",
        "build_flavor" : "default",
        "build_type" : "deb",
        "build_hash" : "78722783c38caa25a70982b5b042074cde5d3b3a",
        "build_date" : "2021-03-18T06:17:15.410153305Z",
        "build_snapshot" : false,
        "lucene_version" : "8.8.0",
        "minimum_wire_compatibility_version" : "6.8.0",
        "minimum_index_compatibility_version" : "6.0.0-beta1"
    },
    "tagline" : "You Know, for Search"
}
```

### Traefik

1. Create a working directory

```bash
sudo mkdir /opt/traefik && sudo chown $USER:$USER /opt/traefik && cd /opt/traefik
```

2. Download Traefik 2.11.16 release from official git [repository](https://github.com/traefik/traefik/releases) and make binary executable

```bash
wget -c -N -O traefik https://github.com/traefik/traefik/releases/download/v2.11.16/traefik_v2.11.16_linux_amd64.tar.gz && chmod +x traefik
tar -xvf traefik_v2.11.16_linux_amd64.tar.gz
```

3. Download ReportPortal Traefik configuration file
```bash
wget -O /etc/traefik/traefik.yml https://raw.githubusercontent.com/reportportal/linux-installation/EPMRPP-66074/update-linux-guide/data/traefik.yml
wget -O /etc/traefik/dynamic_conf.yml https://raw.githubusercontent.com/reportportal/linux-installation/master/data/dynamic_conf.yml
```
4.  Create Service for traefik
```	
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
```

5. Start Traefik

```bash
sudo systemctl daemon-reload
sudo systemctl enable traefik
sudo systemctl start traefik
```
6. Check Traefik status

```
sudo systemctl status traefik
```

### Install and configure Go
```bash
wget https://go.dev/dl/go1.22.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```
## ReportPortal Services

![Analyzer](https://img.shields.io/badge/Analyzer-5.13.1-9cf?style=flat-square)
![UI](https://img.shields.io/badge/UI-5.12.13-9cf?style=flat-square)
![API](https://img.shields.io/badge/API-5.13.2-9cf?style=flat-square)
![Migration](https://img.shields.io/badge/Migration-5.13.0-9cf?style=flat-square)
![Index](https://img.shields.io/badge/Index-5.13.0-9cf?style=flat-square)
![UAT](https://img.shields.io/badge/UAT-5.13.0-9cf?style=flat-square)
![Jobs](https://img.shields.io/badge/UAT-5.13.0-9cf?style=flat-square)

### Repositories

[![Index](https://img.shields.io/github/downloads/reportportal/service-index/total?label=Index%40downloads&style=flat-square)](https://github.com/reportportal/service-index/releases/) 
[![UI](https://img.shields.io/github/downloads/reportportal/service-ui/total?label=UI%40downloads&style=flat-square)](https://github.com/reportportal/service-ui/releases/)
[![API](https://img.shields.io/maven-central/v/com.epam.reportportal/service-api?label=API%40maven-central&style=flat-square)](https://search.maven.org/artifact/com.epam.reportportal/service-api/5.13.0/jar)
[![UAT](https://img.shields.io/maven-central/v/com.epam.reportportal/service-authorization?label=UAT%40maven-central&style=flat-square)](https://search.maven.org/artifact/com.epam.reportportal/service-authorization/5.3.5/jar)

### Preparation

How to install Python 3.11.11, Python 3.11.11 DEV and Python 3.11.11 VENV on [Ubuntu](https://www.python.org/downloads/) LTS 24.04 / [Red Hat family](https://www.python.org/downloads/) 6, 7, 8 (RHEL, AlmaLinux, etc).

For example for Ubuntu 24.04 OS:
Create Env variables
```bash
PY_VERSION="3.11.11"
PY_TARBALL="Python-${PY_VERSION}.tar.xz"
```
Get required python version
```bash
sudo wget "https://www.python.org/ftp/python/${PY_VERSION}/${PY_TARBALL}"
```

Also you need to install `ZIP`, `GCC` and `software-properties-common` (for Ubuntu)

```bash
sudo apt install zip software-properties-common gcc -y
```
compile python
```bash
tar -xf "${PY_TARBALL}"
cd "Python-${PY_VERSION}"
./configure
make -j"$(nproc)"
sudo make altinstall
```
 
Add environment variables:

```bash
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

RP_POSTGRES_USER=<your_rpdbuser>
RP_POSTGRES_PASSWORD=<your_rpdbuser_password>
RP_RABBITMQ_USER=<your_rpmquser>
RP_RABBITMQ_PASSWORD=<your_rpmquser_password>

RP_AMQP_HOST=<your_rabbitmq_host>
RP_AMQP_PORT=your_rabbit_port>
RP_AMQP_APIPORT=<your_rabbit_api_port>
RP_AMQP_USER=<your_rabbit_user>
RP_AMQP_PASS=<your_rabbit_pass>
RP_AMQP_APIUSER=<your_rabbit_api_user>
RP_AMQP_APIPASS=<yoyr_rabbit_api_pass>
RP_AMQP_ANALYZER_VHOST=<your_analyzer_virtual_host>
AMQP_URL="amqp://${RABBITMQ_DEFAULT_USER-rabbitmq}:${RABBITMQ_DEFAULT_PASS-rabbitmq}@${RP_AMQP_HOST}:${RP_AMQP_PORT}${RP_AMQP_ANALYZER_VHOST}"

DATASTORE_TYPE="filesystem" 
```

Create a working directory 

```bash
sudo mkdir /opt/reportportal/ && \
sudo chown -R $USER:$USER /opt/reportportal/ && \
cd /opt/reportportal/
```

### Analyzer

1. Download last relaese of Analyzer service, unzip and enter to directory:

```bash
curl -LO https://github.com/reportportal/service-auto-analyzer/archive/refs/tags/${SERVICE_ANALYZER}.zip && \
unzip ${SERVICE_ANALYZER}.zip && \
cd /opt/reportportal/service-auto-analyzer-${SERVICE_ANALYZER}
```

2. Work with a virtual environment:
```bash
# Create a virtual environment with any name (for example /vrpanalyzer)
sudo python3.11 -m venv /analyzer

# Install python required libraries
sudo /analyzer/bin/pip install --upgrade pip
sudo /analyzer/bin/pip install --no-cache-dir -r requirements.txt

# Activate the virtual environment
source /vrpanalyzer/bin/activate

# Install stopwords package from the nltk library
sudo /analyzer/bin/python3.11 -m nltk.downloader -d /usr/share/nltk_data stopwords
```

3. Start the uwsgi server, you can change properties, such as the worker's quantity for running the analyzer in several processes. 

Set in ***app.ini*** your virtual environment specified above:

```bash
virtualenv = analyzer
```

Set in ***app.py*** RabbitMQ URL `amqp://user:password@localhost:5672`, binary store type `filesystem`, and directory name (for example `rpstorage`)

```bash
# "amqpUrl":           os.getenv("AMQP_URL", "amqp://user:password@localhost:5672").strip("/").strip("\\"),
# "binaryStoreType":   os.getenv("ANALYZER_BINARYSTORE_TYPE", "filesystem"),
# "filesystemDefaultPath": os.getenv("FILESYSTEM_DEFAULT_PATH", "rpstorage").strip()

```

Activate the virtual environment

```bash
source /analyzer/bin/activate
```

Install stopwords package from the nltk library

```bash
sudo /analyzer/bin/python3.11 -m nltk.downloader -d /usr/share/nltk_data stopwords
```

Start Analyzer

```bash
/analyzer/bin/uwsgi --ini app.ini > /dev/null 2>&1 &
```
for analyzer train consider the same steps, but using "analyzer-train" instead "analyzer", also you will require the following environment variables:
```bash
INSTANCE_TASK_TYPE: train
UWSGI_WORKERS: 1
```
### Migration
1. Prepare automatic database Authentication
```bash
PGPASS_FILE="$HOME/.pgpass"
echo "Configuring automatic authentication in $PGPASS_FILE..."
cat <<EOF > "$PGPASS_FILE"
${POSTGRES_HOST}:${POSTGRES_PORT}:${RP_POSTGRES_DB}:${RP_POSTGRES_USER}:${POSTGRES_PASSWORD}
EOF
chmod 600 "$PGPASS_FILE"
```

2. Download service

```bash
cd /opt/reportportal/ && \
wget -c -N -O migrations.zip https://github.com/reportportal/migrations/archive/${MIGRATIONS_VERSION}.zip && unzip migrations.zip && mv migrations-${MIGRATIONS_VERSION} migrations && rm -f migrations.zip
```

3. Run service

You need to execute all `up` scripts to prepare your database for ReportPortal services, run the following script in orther to install it:

```bash
for FILE in $(ls migrations/migrations/*.up.sql | sort -V); do
  echo "Applying migration: $FILE"
  psql -h "$POSTGRES_HOST" \
       -p "$POSTGRES_PORT" \
       -U "$RP_POSTGRES_USER" \
       -d "$RP_POSTGRES_DB" \
       -a -f "$FILE"
done
```

4. Clean workspace

```bash
rm -f "$PGPASS_FILE"
rm -rf ./migrations/
```

### Index

1. Download service

```bash
cd /opt/reportportal/ && \
wget -c -N -O service-index https://github.com/reportportal/service-index/releases/download/$SERVICE_INDEX_VERSION/service-index_linux_amd64
```

2. Run service

```bash
sudo chmod +x service-index && \
sudo RP_SERVER_PORT=9000 LB_URL=http://localhost:8081 ./service-index 2>&1 &
```

### API

1. Download API service 

```bash
cd /opt/reportportal/ && \
curl -L $MAVEN_REPO/service-api/$API_VERSION/service-api-$API_VERSION-exec.jar -o service-api.jar
```

2. Run API service

```bash
sudo RP_AMQP_HOST=$RP_AMQP_HOST RP_AMQP_APIUSER=$RP_RABBITMQ_USER RP_AMQP_APIPASS=$RP_RABBITMQ_PASSWORD RP_AMQP_USER=$RP_RABBITMQ_USER RP_AMQP_PASS=$RP_RABBITMQ_PASSWORD RP_DB_USER=$RP_POSTGRES_USER RP_DB_PASS=$RP_POSTGRES_PASSWORD RP_DB_HOST=$RP_DB_HOST java $SERVICE_API_JAVA_OPTS -jar service-api.jar 2>&1 &
```

### UAT

1. Download service

```bash
cd /opt/reportportal/ && \
curl -L $MAVEN_REPO/service-authorization/$UAT_VERSION/service-authorization-$UAT_VERSION-exec.jar -o service-uat.jar
```

2. Run service

```bash
RP_DB_HOST=$RP_DB_HOST RP_DB_USER=$RP_POSTGRES_USER RP_DB_PASS=$RP_POSTGRES_PASSWORD java $SERVICE_UAT_JAVA_OPTS -jar service-uat.jar 2>&1 &
```
### JOBS

1. Download service

```bash
cd /opt/reportportal/ && \
curl -L $MAVEN_REPO/service-jobs/$SERVICE_JOBS/service-jobs-$SERVICE_JOBS-exec.jar -o service-uat.jar
```

2. Run service

```bash
RP_DB_HOST=$RP_DB_HOST RP_DB_USER=$RP_POSTGRES_USER RP_DB_PASS=$RP_POSTGRES_PASSWORD java $SERVICE_JOBS_JAVA_OPTS -jar service-uat.jar 2>&1 &
```

### UI

1. Create UI work directory

```bash
mkdir -p /opt/reportportal/ui && cd /opt/reportportal/
```

2. Download UI service 

```bash
curl -L https://github.com/reportportal/service-ui/releases/download/$UI_VERSION/service-ui_linux_amd64 -o service-ui && \
mv service-ui ui/ && \
chmod -R +x ui/* && \
curl -LO https://github.com/reportportal/service-ui/releases/download/$UI_VERSION/ui.tar.gz && \
mkdir public && \
tar -zxvf ui.tar.gz -C public && rm -f ui.tar.gz
```

3. Run service

```bash
cd ui/ && RP_STATICS_PATH=../public RP_SERVER_PORT=3000 ./service-ui 2>&1 &
```

Check availability of ReportPortal

![RabbitMQ](img/reportportal.gif)
