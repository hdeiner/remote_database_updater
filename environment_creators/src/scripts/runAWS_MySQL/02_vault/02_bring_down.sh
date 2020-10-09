#!/usr/bin/env bash

figlet -w 160 -f standard "Bring Down Vault"

figlet -w 160 -f small "UnTerraform Vault Server"
cd ../../iac/terraform/vault
terraform destroy -auto-approve
rm -rf .vault_dns
cd -
