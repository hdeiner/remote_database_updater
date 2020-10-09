#!/usr/bin/env bash
figlet -w 160 -f standard "Run MySQL"

figlet -w 160 -f small "Get Vault Connection"
export ENVIRONMENT=$(<.environment)
export VAULT_ADDRESS="http://"$(<.vault_dns)":8200"
mkdir .vault_howardeiner
aws s3 cp s3://zipster-aws-on-demand-vault/root_token .vault_howardeiner/root_token
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
vault login -address=$VAULT_ADDRESS $VAULT_TOKEN > /dev/null

figlet -w 160 -f small "Get mysql-data from S3"
cd src/iac/docker-compose
aws s3 cp s3://zipster-aws-on-demand-mysql mysql-data-download --recursive
tar -xzf mysql-data-download/mysql-data.tar.gz mysql-data
rm -rf mysql-data-download/
cd -

figlet -w 160 -f small "Bring up Local MySQL Container"
docker-compose -f src/iac/docker-compose/use_mysql.yml up -d

figlet -w 160 -f small "Set MYSQL Secrets in Vault"
export MYSQL_DNS_NAME="`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname || die \"wget public-hostname has failed: $?\"`"
test -n "MYSQL_DNS_NAME" || die 'cannot obtain public-hostname'
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=password
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL address=$MYSQL_DNS_NAME port=$MYSQL_PORT user=$MYSQL_USER password=$MYSQL_PASSWORD status=started

figlet -w 160 -f small "Wait for MYSQL to start"
export MYSQL_TEST_IP=127.0.0.1
while true ; do
 result=$(mysql -u $MYSQL_USER --password=$MYSQL_PASSWORD -h $MYSQL_TEST_IP -e 'select count(*) from sys.sys_config;' | grep -E 'count' | wc -l)
  if [ \$result != 0 ] ; then
   echo "MySQL is running"
   break
  fi
  sleep 5
done
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL address=$MYSQL_DNS_NAME port=3306 user=root password=password status=running
