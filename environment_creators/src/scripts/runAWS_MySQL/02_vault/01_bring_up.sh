#!/usr/bin/env bash

figlet -w 160 -f standard "Bring Up Vault"

figlet -w 160 -f small "Terraform Vault Server"
cd ../../iac/terraform/vault
terraform apply -auto-approve
echo `terraform output vault_dns | grep -o '".*"' | cut -d '"' -f2` > .vault_dns
cd -

echo "Vault DNS is";cat ../../iac/terraform/vault/.vault_dns
echo "Vault root token is ";aws s3 cp s3://zipster-aws-on-demand-vault/root_token -
