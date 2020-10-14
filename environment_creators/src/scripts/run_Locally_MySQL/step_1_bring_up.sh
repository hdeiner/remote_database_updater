#!/usr/bin/env bash

figlet -w 160 -f standard "Bring All Up on Local Machine"

figlet -w 160 -f small "Get Vault Secrets and Volumes from S3"
aws s3 cp s3://zipster-aws-on-demand-vault .vault_howardeiner  --recursive
docker run --rm -v dockercompose_vault_files:/volume -v $PWD/.vault_howardeiner:/backup alpine sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/vault_files.tar.bz2"
docker run --rm -v dockercompose_vault_logs:/volume -v $PWD/.vault_howardeiner:/backup alpine sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/vault_logs.tar.bz2"

figlet -w 160 -f small "Bring up Local Vault Container"
docker-compose -f ../../iac/docker-compose/use_vault.yml up -d

figlet -w 160 -f small "Wait for Vault to Start"
export VAULT_ADDRESS=http://127.0.0.1:8200
while true ; do
  result=$(vault status -address=$VAULT_ADDRESS 2>&1 | grep -E "Key.*Value" | wc -l)
  if [ $result != 0 ] ; then
    echo "Vault has started"
    break
  fi
  sleep 5
done

figlet -w 160 -f small "Unseal Vault"
docker exec vault_container vault operator unseal $(<.vault_howardeiner/unsealkey_1) > /dev/null
docker exec vault_container vault operator unseal $(<.vault_howardeiner/unsealkey_2) > /dev/null
docker exec vault_container vault operator unseal $(<.vault_howardeiner/unsealkey_3) > /dev/null

figlet -w 160 -f small "Bring up Local MySQL Container"
docker-compose -f ../../iac/docker-compose/use_mysql.yml up -d

figlet -w 160 -f small "Set MYSQL Secrets in Vault"
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
export ENVIRONMENT=howarddeiner
vault login -address=$VAULT_ADDRESS $VAULT_TOKEN
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL address=mysql_container port=3306 user=root password=password status=created

figlet -w 160 -f small "Wait for MYSQL to start"
export MYSQL_TEST_IP=127.0.0.1
while true ; do
 result=$(mysql -u root --password=password -h $MYSQL_TEST_IP -e 'select count(*) from sys.sys_config;' | grep -E 'count' | wc -l)
  if [ $result != 0 ] ; then
   echo "MySQL has started"
   break
  fi
  sleep 5
done
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL address=mysql_container port=3306 user=root password=password status=running

figlet -w 160 -f small "Create Database"
cd ../../../..
python remote_database_updater.py -f localhost_mysql.csv
cd -

figlet -w 160 -f small "Bring up Local Spark Container"
# Inside docker-compose environment, containers will talk on their own internal network
export VAULT_ADDRESS=http://vault_container:8200
docker-compose -f ../../iac/docker-compose/use_spark.yml up -d
export VAULT_ADDRESS=http://127.0.0.1:8200
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/SPARK address=spark_container status=started 2>/dev/null

figlet -w 160 -f small "Wait for Spark to start"
while true ; do
  echo "doing test"
  curl http://localhost:8080/zipster -d '{"radius":"2.0", "zipcode":"07440"}'
  result=$(curl http://localhost:8080/zipster -d '{"radius":"2.0", "zipcode":"07440"}' 2>&1 | grep -E "NA-US-NJ-WAYNE" | wc -l)
  if [ $result != 0 ] ; then
    echo "Spark has started"
    break
  fi
  sleep 5
done

vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/SPARK address=spark_container status=running
