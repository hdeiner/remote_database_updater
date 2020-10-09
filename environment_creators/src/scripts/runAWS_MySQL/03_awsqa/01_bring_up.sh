#!/usr/bin/env bash

figlet -w 160 -f standard "Bring Up AWSQA Environment"

export ENVIRONMENT=AWSQA

figlet -w 160 -f small "Terraform AWSQA Environment"
cd ../../iac/terraform/awsqa
terraform apply -var environment=$ENVIRONMENT -auto-approve
echo `terraform output spark_dns | grep -o '".*"' | cut -d '"' -f2` > .spark_dns
cd -

export VAULT_ADDRESS="http://"$(<../../iac/terraform/vault/.vault_dns)":8200"
echo "VAULT_ADDRESS is "$VAULT_ADDRESS
mkdir .vault_howardeiner
aws s3 cp s3://zipster-aws-on-demand-vault/root_token .vault_howardeiner/root_token
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
echo "VAULT_TOKEN is "$VAULT_TOKEN
vault login -address=$VAULT_ADDRESS $VAULT_TOKEN > /dev/null

export MYSQL_DNS_NAME=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^address[ ]*.' | awk '{print $2}'`
echo "MYSQL_DNS_NAME is "$MYSQL_DNS_NAME
export MYSQL_USER=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^user[ ]*.' | awk '{print $2}'`
echo "MYSQL_USER is "$MYSQL_USER
export MYSQL_PASSWORD=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/MYSQL | grep -E '^password[ ]*.' | awk '{print $2}'`
echo "MYSQL_PASSWORD is "$MYSQL_PASSWORD

export SPARK_DNS_NAME=$(echo `cat ../../iac/terraform/awsqa/.spark_dns`)
vault kv put -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/SPARK/ address=$SPARK_DNS_NAME > /dev/null
echo "SPARK_DNS_NAME is "$SPARK_DNS_NAME

rm -rf .vault_howardeiner
