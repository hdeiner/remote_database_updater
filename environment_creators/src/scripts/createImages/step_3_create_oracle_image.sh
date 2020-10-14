#!/usr/bin/env bash

figlet -w 160 -f standard "Create Oracle Image"

figlet -w 160 -f small "Bring up Local Oracle Container"
docker-compose -f ../../iac/docker-compose/create_oracle.yml up -d

echo "Waiting for Oracle to start"
while true ; do
  result=$(docker logs oracle_container 2>&1 | grep  -Ec "Done ! The database is ready for use .")
  if [ $result != 0 ] ; then
    sleep 45  # it only says that it's ready!
    echo "Oracle has started"
    break
  fi
  sleep 5
done

figlet -w 160 -f small "Commit and Push to DockerHub"
echo 'STUTDOWN;' | docker exec -it oracle_container /u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus system/Oradoc_db1@localhost:1521/ORCLCDB.localdomain
sleep 15
docker rmi -f howarddeiner/zipster-aws-on-demand-oracle
docker stop oracle_container
docker commit oracle_container howarddeiner/zipster-aws-on-demand-oracle
docker login
docker push howarddeiner/zipster-aws-on-demand-mysql

figlet -w 160 -f small "Bring Down Oracle Container"
docker-compose -f ../../iac/docker-compose/create_oracle.yml down
docker volume rm docker-compose_oracle_data