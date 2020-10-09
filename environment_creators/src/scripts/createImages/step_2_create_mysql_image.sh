#!/usr/bin/env bash

figlet -w 160 -f standard "Create MySQL Image"

figlet -w 160 -f small "Bring up Local Vault Container"
docker-compose -f ../../iac/docker-compose/create_mysql.yml up -d

figlet -w 160 -f small "Wait for MySQL to Start"
while true ; do
  result=$(docker logs mysql_container 2>&1 | grep  -Ec ".*ready for connections.*Version.*port: 3306.*MySQL Community Server - GPL")
  if [ $result != 0 ] ; then
    echo "MySQL has started"
    break
  fi
  sleep 5
done

#figlet -w 160 -f small "Ready MySQL for FlyWay"
#echo "CREATE USER 'FLYWAY' IDENTIFIED BY 'FLWAY';" | mysql -h 127.0.0.1 -P 3306 -u root --password=password  zipster > /dev/null





### THESE COMMANDS WILL CREATE THE DATABASE WITHOUT FLYWAY
#mysql -h 127.0.0.1 -P 3306 -u root --password=password  zipster  < ../../sql/V1_1__Zipcode_Schema.sql
#mysql -h 127.0.0.1 -P 3306 -u root --password=password  zipster  < ../../sql/V1_2__Zipcode_Static_Data.sql
#mysql -h 127.0.0.1 -P 3306 -u root --password=password  zipster  < ../../sql/V2_1__Add_Spatial_Data.sql




#figlet -w 160 -f small "Load Initial Data Into MySQL"
#../../../flyway-4.2.0/flyway -target=3_1 migrate

figlet -w 160 -f small "Commit and Push to DockerHub"
docker exec mysql_container mysqladmin --password=password shutdown
sleep 15
docker rmi -f howarddeiner/zipster-aws-on-demand-mysql
docker stop mysql_container
docker commit mysql_container howarddeiner/zipster-aws-on-demand-mysql
docker login
docker push howarddeiner/zipster-aws-on-demand-mysql

#figlet -w 160 -f small "Serialize the mysql-data"
#cd ../../iac/docker-compose/
#sudo -S <<< "password"  tar -czf mysql-data.tar.gz mysql-data
#sudo -S <<< "password" rm -rf mysql-data
#cd -

#figlet -w 160 -f small "Store mysql-data in S3"
#aws s3 rb s3://zipster-aws-on-demand-mysql --force
#aws s3 mb s3://zipster-aws-on-demand-mysql
#aws s3 cp ../../iac/docker-compose/mysql-data.tar.gz s3://zipster-aws-on-demand-mysql

figlet -w 160 -f small "Bring Down MySQL Continer"
docker-compose -f ../../iac/docker-compose/create_mysql.yml down
docker volume rm docker-compose_mysql_data