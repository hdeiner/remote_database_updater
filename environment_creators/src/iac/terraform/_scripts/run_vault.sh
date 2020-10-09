#!/usr/bin/env bash

figlet -w 160 -f standard "Run Vault"

figlet -w 160 -f small "Get Vault Files from S3"
aws s3 cp s3://zipster-aws-on-demand-vault .vault_howardeiner  --recursive
docker run --rm -v dockercompose_vault_files:/volume -v $PWD/.vault_howardeiner:/backup alpine sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/vault_files.tar.bz2"
docker run --rm -v dockercompose_vault_logs:/volume -v $PWD/.vault_howardeiner:/backup alpine sh -c "rm -rf /volume/* /volume/..?* /volume/.[!.]* ; tar -C /volume/ -xjf /backup/vault_logs.tar.bz2"

figlet -w 160 -f small "Bring up Local Vault Container"
docker-compose -f src/iac/docker-compose/use_vault.yml up -d

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
