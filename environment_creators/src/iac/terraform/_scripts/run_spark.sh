#!/usr/bin/env bash
figlet -w 160 -f standard "Run Spark"

figlet -w 160 -f small "Get Vault Connection"
export ENVIRONMENT=$(<.environment)
export VAULT_ADDRESS="http://"$(<.vault_dns)":8200"
mkdir .vault_howardeiner
aws s3 cp s3://zipster-aws-on-demand-vault/root_token .vault_howardeiner/root_token
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
vault login -address=$VAULT_ADDRESS $VAULT_TOKEN > /dev/null

figlet -w 160 -f small "Get MYSQL Instance Connection"
while true ; do
  export MYSQL_STATUS=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^status[ ]*.' | awk '{print $2}'`
  if [ $MYSQL_STATUS == 'running' ] ; then
    echo "MySQL is running"
    break
  fi
  sleep 5
done
export MYSQL_DNS_NAME=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^address[ ]*.' | awk '{print $2}'`
echo "MySQL is running on "$MYSQL_DNS_NAME
export MYSQL_USER=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^user[ ]*.' | awk '{print $2}'`
echo "MySQL user is "$MYSQL_USER
export MYSQL_PASSWORD=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^password[ ]*.' | awk '{print $2}'`
echo "MySQL password is "$MYSQL_PASSWORD

figlet -w 160 -f small "Bring up Local Spark Container"
docker-compose -f src/iac/docker-compose/use_spark.yml up -d

figlet -w 160 -f small "Set Spark Secrets in Vault"
export SPARK_PUBLIC_IP="`wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4 || die \"wget public-ipv4 has failed: $?\"`"
test -n "SPARK_PUBLIC_IP" || die 'cannot obtain public-ipv4'
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/SPARK_INSTANCE_$SPARK_PUBLIC_IP status=started

figlet -w 160 -f small "Wait for Spark to start"
while true ; do
  result=$(curl http://localhost:8080/zipster -d '{"radius":"2.0", "zipcode":"07440"}' 2>&1 | grep -E "NA-US-NJ-WAYNE" | wc -l)
  if [ $result != 0 ] ; then
    echo "Spark is running"
    break
  fi
  sleep 5
done
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/SPARK_INSTANCE_$SPARK_PUBLIC_IP status=running
