#!/usr/bin/env bash

figlet -w 160 -f standard "Create Spark Image"

figlet -w 160 -f small "Build Zipster"
cd ../../..
mvn -q -f pom.xml clean compile package
cp target/zipster-1.0-SNAPSHOT.jar src/iac/docker/spark/.
cd -

figlet -w 160 -f small "Bring up Local Spark Container"
docker-compose -f ../../iac/docker-compose/create_spark.yml up -d

figlet -w 160 -f small "Commit and Push to DockerHub"
docker rmi -f howarddeiner/zipster-aws-on-demand-spark
docker stop spark_container
docker commit spark_container howarddeiner/zipster-aws-on-demand-spark
docker login
docker push howarddeiner/zipster-aws-on-demand-spark

figlet -w 160 -f small "Bring Down Spark Container"
docker-compose -f ../../iac/docker-compose/create_spark.yml down

figlet -w 160 -f small "Cleanup"
cd ../../..
mvn -q -f pom.xml clean
cd -
docker rmi -f docker-compose_spark_service
rm ../../iac/docker/spark/zipster-1.0-SNAPSHOT.jar