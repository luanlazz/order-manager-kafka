# Order Manager (Kafka)

Implementation based on Confluent repository [kafka-streams-examples](https://github.com/confluentinc/kafka-streams-examples/tree/6.0.0-post/src/main/java/io/confluent/examples/streams/microservices) and [examples](https://github.com/confluentinc/examples).                                  

>## Instructions to run

You can run in two ways, first by the script (start.sh) or manually:

#### Script

1. Execute script ./start.sh
2. To stop ./stop.sh

#### Manual

1. Start Zookeeper with command: `zookeeper-server-start.sh config/zookeeper.properties`
2. Start Kafka Server with command: `kafka-server-start.sh config/server.properties`
3. Start Confluent Platform with command: `confluent local services start`
4. Run the service!

>## Requirements

1. Apache Zookeeper
2. Apache Kafka
3. Confluent Platform 6.0.1
4. Java 8