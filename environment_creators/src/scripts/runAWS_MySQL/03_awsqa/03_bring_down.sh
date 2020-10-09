#!/usr/bin/env bash

figlet -w 170 -f standard "Bring Down AWSQA Environment"
export ENVIRONMENT=AWSQA

figlet -w 160 -f small "Remove ENVIRONMENT from Vault"
export VAULT_ADDRESS="http://"$(<../../iac/terraform/vault/.vault_dns)":8200"
mkdir .vault_howardeiner
aws s3 cp s3://zipster-aws-on-demand-vault/root_token .vault_howardeiner/root_token
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
vault login -address=$VAULT_ADDRESS $VAULT_TOKEN > /dev/null

for path in $(vault kv list -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/ | tail -n+3);
  do
    vault kv delete -address=$VAULT_ADDRESS ENVIRONMENTS/$ENVIRONMENT/${path};
  done

rm -rf .vault_howardeiner/root_token

figlet -w 160 -f small "UnTerraform AWSQA"
cd ../../iac/terraform/awsqa
terraform destroy -var environment=AWSQA -auto-approve
rm -rf .environment .mysql_dns .spark_dns
cd -
