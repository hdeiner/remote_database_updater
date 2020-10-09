#!/usr/bin/env bash

figlet -w 160 -f standard "Test in AWSQA Environment"

export ENVIRONMENT=AWSQA

export VAULT_ADDRESS="http://"$(<../../iac/terraform/vault/.vault_dns)":8200"
mkdir .vault_howardeiner
aws s3 cp s3://zipster-aws-on-demand-vault/root_token .vault_howardeiner/root_token
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
vault login -address=$VAULT_ADDRESS $VAULT_TOKEN > /dev/null

export SPARK_DNS_NAME=`vault kv get -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/SPARK | grep -E '^address[ ]*.' | awk '{print $2}'`

TEST_COMMAND="curl http://"$SPARK_DNS_NAME":8080/zipster -d '{\"zipcode\":\"07440\","radius":\"2\"}'"
echo $TEST_COMMAND
eval $TEST_COMMAND
echo ""

rm -rf .vault_howardeiner
