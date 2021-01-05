#!/bin/bash

# Source library
source ./utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_jot || exit 1
check_netstat || exit 1
check_running_cp ${CONFLUENT} || exit 1
check_sqlite3 || exit 1

./stop.sh

compile_kafka_streams_examples || exit 1;

#confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:latest
grep -qxF 'auto.offset.reset=earliest' $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties || echo 'auto.offset.reset=earliest' >> $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties
confluent local services start
sleep 5

export BOOTSTRAP_SERVERS=localhost:9092
export SCHEMA_REGISTRY_URL=http://localhost:8081
export SQLITE_DB_PATH=${PWD}/db/data/microservices.db

echo "Creating demo topics"
./scripts/create-topics.sh topics.txt

echo "Setting up sqlite DB"
(cd db; sqlite3 data/microservices.db < ./customers.sql)

echo ""
echo "Submitting connectors"

# Kafka Connect to source customers from sqlite3 database and produce to Kafka topic "customers"
INPUT_FILE=./connectors/connector_jdbc_customers_template.config
OUTPUT_FILE=./connectors/rendered-connectors/connector_jdbc_customers.config
source ./scripts/render-connector-config.sh
confluent local services connect connector config jdbc-customers --config $OUTPUT_FILE 2> /dev/null

# Find an available local port to bind the REST service to
FREE_PORT=$(jot -r 1  10000 65000)
COUNT=0
while [[ $(netstat -ant | grep "$FREE_PORT") != "" ]]; do
  FREE_PORT=$(jot -r 1  10000 65000)
  COUNT=$((COUNT+1))
  if [[ $COUNT > 5 ]]; then
    echo "Could not allocate a free network port. Please troubleshoot"
    exit 1
  fi
done
echo "Port $FREE_PORT looks free for the Orders Service"
echo "Running Microservices"
( RESTPORT=$FREE_PORT JAR=$(pwd)"/target/kafka-streams-examples-$CONFLUENT-standalone.jar" ./scripts/run-services.sh > logs/run-services.log 2>&1 & )

echo "Waiting for data population before starting ksqlDB applications"
sleep 150
# Create ksqlDB queries
ksql http://localhost:8088 <<EOF
run script 'statements.sql';
exit ;
EOF