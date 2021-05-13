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

![Ubuntu](https://img.shields.io/badge/Ubuntu-18.04-orange)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04-orange)

![RHEL](https://img.shields.io/badge/RHEL-6.10-red)
![RHEL](https://img.shields.io/badge/RHEL-7.9-red)
![RHEL](https://img.shields.io/badge/RHEL-8.x-red)
![CentOS](https://img.shields.io/badge/CentOS-6.10-yellow)
![CentOS](https://img.shields.io/badge/CentOS-7.9-yellow)
![CentOS](https://img.shields.io/badge/CentOS-8.x-yellow)

## Table of contents

* [Description](#Descriprion)
* [Supported OS](#Supported-OS)
* [Required Services](#Required-Services)
    * [PostgreSQL](#PostgreSQL)
    * [RabbitMQ](#RabbitMQ)
    * [ElasticSearch](#ElasticSearch)
    * [Traefik](#Traefik)
* [ReportPortal Services](#ReportPortal-Services)
    * [Preparation](#Preparation)
    * [Analyzer](#Analyzer)
    * [Migration](#Migration)
    * [Index](#Index)
    * [API](#API)
    * [UAT](#UAT)
    * [UI](#UI)


## Required Services
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12.6-blue)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-3.8.14-blue)
![ElasticSearch](https://img.shields.io/badge/ElasticSearch-7.10.1-blue)
![Traefik](https://img.shields.io/badge/Traefik-1.7.29-blue)

### PostgreSQL

How to install PostgreSQL 12.6 on [Ubuntu](https://www.postgresql.org/download/linux/ubuntu/) LTS 18.04, 20.04 / [Red Hat family](https://www.postgresql.org/download/linux/redhat/) 6, 7, 8 (RHEL, CentOS, etc) 

1. After successful installation, you need to prepare the database to ReportPortal services `sudo su - postgres -c "psql"`

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
* Ubuntu: `/etc/postgresql/12/main/pg_hba.conf`
* RHEL: `/var/lib/pgsql/12/data/pg_hba.conf`

3. After the changes above, restart the PostgreSQL service 
```bash
sudo systemctl restart postgresql
```

4. Create the ***pgcrypto*** extantion for PostgreSQL `reportportal` database

```bash
psql -U rpuser -d reportportal -c "CREATE EXTENSION pgcrypto;"
```

### RabbitMQ

How to install RabbitMQ 3.8.14 on [Ubuntu](https://www.rabbitmq.com/install-debian.html#apt) LTS 18.04, 20.04 / [Red Hat family](https://www.rabbitmq.com/install-rpm.html) 6, 7, 8 (RHEL, CentOS, etc) 

1. After installation enable RabbitMQ web management console:

```bash
sudo rabbitmq-plugins enable rabbitmq_management
```

2. Check and provide ownership of RabbitMQ files to the RabbitMQ user:

```bash
sudo chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
```

3. Create an admin user for RabbitMQ web management console

```bash
sudo rabbitmqctl add_user admin <strong_password>
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

4. Configure user, permissions and vhost for ReportPortal. Run the following commands in order to configure your RabbitMQ work with ReportPortal. Please determine the name and the password for your ReportPortal Rabbitmq user in advance

```bash
sudo rabbitmqctl add_user <your_rpmquser> <your_rpmquser_password>
sudo rabbitmqctl set_user_tags <your_rpmquser> administrator
sudo rabbitmqctl set_permissions -p / <your_rpmquser> ".*" ".*" ".*"
sudo rabbitmqctl add_vhost analyzer
sudo rabbitmqctl set_permissions -p analyzer <your_rpmquser> ".*" ".*" ".*"
```

To check RabbitMQ look forward <you_IP>:15672

![RabbitMQ](img/rabbitmq.gif)

### ElasticSearch

How to install ElasticSearch 7.10.1 on [Ubuntu](https://www.elastic.co/guide/en/elasticsearch/reference/7.10/deb.html) LTS 18.04, 20.04 / [Red Hat family](https://www.elastic.co/guide/en/elasticsearch/reference/current/rpm.html) 6, 7, 8 (RHEL, CentOS, etc). Also you need to install `openjdk-11-jre-headless` and `openjdk-8-jdk`

To check ElsaticSearch use the `curl -X GET "localhost:9200/"`. Output will be:

```json
{
    "name" : "reportportal",
    "cluster_name" : "elasticsearch",
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

1. Create work directory

```bash
sudo mkdir /opt/traefik && sudo chown $USER:$USER /opt/traefik && cd /opt/traefik
```

2. Download Traefik 1.7.29 release from offical git [repository](https://github.com/traefik/traefik/releases) and make binary exetutable

```bash
wget -c -N -O traefik https://github.com/traefik/traefik/releases/download/v1.7.29/traefik_linux-amd64 && chmod +x traefik
```

3. Download ReportPortal Treafik configuration file

```bash
curl -LO https://raw.githubusercontent.com/reportportal/linux-installation/master/data/traefik.toml
```

4. Start Traefik

```bash
sudo ./traefik --configFile=traefik.toml 2>&1 &
```

## ReportPortal Services

![Analyzer](https://img.shields.io/badge/Analyzer-5.3.5-9cf)
![UI](https://img.shields.io/badge/UI-5.3.5-9cf)
![API](https://img.shields.io/badge/API-5.3.5-9cf)
![Migration](https://img.shields.io/badge/Migration-5.3.5-9cf)
![Index](https://img.shields.io/badge/Index-5.0.10-9cf)
![UAT](https://img.shields.io/badge/UAT-5.3.5-9cf)


### Preparation

How to install Python 3.7, Python 3.7 DEV and Python 3.7 VENV on [Ubuntu](https://www.python.org/downloads/) LTS 18.04, 20.04 / [Red Hat family](https://www.python.org/downloads/) 6, 7, 8 (RHEL, CentOS, etc).

For example for Ubunto 18.04 OS:
```bash
sudo apt install python3.7 python3.7-dev python3.7-venv -y
```

Also you need to install `ZIP`, `GCC` and `software-properties-common` (for Ubuntu)

```bash
sudo apt install zip software-properties-common gcc -y
```
 
Add environment variables:

```bash
REPO_URL_BASE="https://dl.bintray.com/epam/reportportal"
REPO_URL_JAR="$REPO_URL_BASE/com/epam/reportportal"
API_VERSION="5.3.5"
UAT_VERSION="5.3.5"
MIGRATIONS_VERSION="5.3.5"
UI_VERSION="5.3.5"
SERVICE_INDEX_VERSION="5.0.10"
SERVICE_ANALYZER="5.3.5"

SERVICE_API_JAVA_OPTS="-Xms1024m -Xmx2048m"
SERVICE_UAT_JAVA_OPTS="-Xms512m -Xmx512m"

RP_POSTGRES_USER=<your_rpdbuser>
RP_POSTGRES_PASSWORD=<your_rpdbuser_password>
RP_RABBITMQ_USER=<your_rpmquser>
RP_RABBITMQ_PASSWORD=<your_rpmquser_password>

```

Create work directory 

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
sudo python3.7 -m venv /vrpanalyzer

# Install python required libraries
sudo /vrpanalyzer/bin/pip install --no-cache-dir -r requirements.txt

# Activate the virtual environment
source /vrpanalyzer/bin/activate

# Install stopwords package from the nltk library
sudo /vrpanalyzer/bin/python3 -m nltk.downloader -d /usr/share/nltk_data stopwords
```

3. Start the uwsgi server, you can change properties, such as the workers quantity for running the analyzer in the several processes. 

Set in ***app.ini*** your virtual environment specified above:

```bash
virtualenv = vrpanalyzer
```

Set in ***app.py*** RabbitMQ URL `amqp://user:password@localhost:5672`, binary store type `filesystem`, and directory name (for expample `rpstorage`)

```bash
# "amqpUrl":           os.getenv("AMQP_URL", "amqp://user:password@localhost:5672").strip("/").strip("\\"),
# "binaryStoreType":   os.getenv("ANALYZER_BINARYSTORE_TYPE", "filesystem"),
# "filesystemDefaultPath": os.getenv("FILESYSTEM_DEFAULT_PATH", "rpstorage").strip()

```

### Migration

1. Download service

```bash
cd /opt/reportportal/ && \
wget -c -N -O migrations.zip https://github.com/reportportal/migrations/archive/${MIGRATIONS_VERSION}.zip && unzip migrations.zip && mv migrations-${MIGRATIONS_VERSION} migrations && rm -f migrations.zip
```

2. Run service

```bash
PGPASSWORD=$RP_POSTGRES_PASSWORD psql -U $RP_POSTGRES_USER -d reportportal -a \ 
  -f migrations/migrations/0_extensions.up.sql \
  -f migrations/migrations/1_initialize_schema.up.sql \
  -f migrations/migrations/2_initialize_quartz_schema.up.sql \
  -f migrations/migrations/3_default_data.up.sql \
  -f migrations/migrations/4_size_limitations.up.sql \
  -f migrations/migrations/5_test_case_id_type.up.sql \
  -f migrations/migrations/6_retries_handling.up.sql \
  -f migrations/migrations/7_auth_integration.up.sql \
  -f migrations/migrations/8_sender_case_enabled_field.up.sql \
  -f migrations/migrations/9_analyzer_params.up.sql \
  -f migrations/migrations/10_attachment_size.up.sql \ 
  -f migrations/migrations/11_password_encoding.up.sql \ 
  -f migrations/migrations/12_remove_ticket_duplicates.up.sql \ 
  -f migrations/migrations/13_add_allocated_storage_per_project.up.sql \ 
  -f migrations/migrations/14_test_case_id_size_increase.up.sql \ 
  -f migrations/migrations/15_statistics_decreasing.up.sql \ 
  -f migrations/migrations/16_remove_unused_indexes.up.sql \ 
  -f migrations/migrations/17_status_enum_extension.up.sql \ 
  -f migrations/migrations/18_job_attributes.up.sql \ 
  -f migrations/migrations/19_retries_handling_extension.up.sql \ 
  -f migrations/migrations/20_deep_merge_statistics_handling.up.sql \ 
  -f migrations/migrations/21_deep_merge_retries_fix.up.sql \ 
  -f migrations/migrations/22_deep_merge_nested_steps_fix.up.sql \ 
  -f migrations/migrations/23_rerun_item_statistics_fix.up.sql \ 
  -f migrations/migrations/24_widget_views_cleanup.up.sql \ 
  -f migrations/migrations/25_deep_merge_nested_steps_path_fix.up.sql 2>&1 &
```

### Index

1. Download service

```bash
cd /opt/reportportal/ && \
wget -c -N -O service-index ${REPO_URL_BASE}/${SERVICE_INDEX_VERSION}/service-index_linux_amd64
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
wget -c -N -O service-api.jar ${REPO_URL_JAR}/service-api/${API_VERSION}/service-api-${API_VERSION}-exec.jar
```

2. Run API service

```bash
sudo RP_AMQP_HOST=localhost RP_AMQP_APIUSER=$RP_RABBITMQ_USER RP_AMQP_APIPASS=$RP_RABBITMQ_PASSWORD RP_AMQP_USER=$RP_RABBITMQ_USER RP_AMQP_PASS=$RP_RABBITMQ_PASSWORD RP_DB_USER=$RP_POSTGRES_USER RP_DB_PASS=$RP_POSTGRES_PASSWORD RP_DB_HOST=localhost java $SERVICE_API_JAVA_OPTS -jar service-api.jar 2>&1 &
```

### UAT

1. Download service

```bash
cd /opt/reportportal/ && \
wget -c -N -O service-uat.jar ${REPO_URL_JAR}/service-authorization/${UAT_VERSION}/service-authorization-${UAT_VERSION}-exec.jar
```

2. Run service

```bash
RP_DB_HOST=localhost RP_DB_USER=$RP_POSTGRES_USER RP_DB_PASS=$RP_POSTGRES_PASSWORD java $SERVICE_UAT_JAVA_OPTS -jar service-uat.jar 2>&1 &
```

### UI

1. Create UI work directory

```bash
mkdir -p /opt/reportportal/ui && cd /opt/reportportal/
```

2. Download UI service 

```bash
wget -c -N -O service-ui ${REPO_URL_BASE}/${UI_VERSION}/service-ui_linux_amd64 && mv service-ui ui
chmod -R +x ui/*
wget -c -N -O ui.tar.gz ${REPO_URL_BASE}/${UI_VERSION}/ui.tar.gz
mkdir public
tar -zxvf ui.tar.gz -C public && rm -f ui.tar.gz
```

3. Run service

```bash
cd ui/ && RP_STATICS_PATH=../public RP_SERVER_PORT=3000 ./service-ui 2>&1 &
```

Chek availability of ReportPortal

![RabbitMQ](img/reportportal.gif)

