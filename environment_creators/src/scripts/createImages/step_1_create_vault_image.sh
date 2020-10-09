#!/usr/bin/env bash

figlet -w 160 -f standard "Create Vault Image"

figlet -w 160 -f small "Bring up Local Vault Container"
docker-compose -f ../../iac/docker-compose/create_vault.yml up -d

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

figlet -w 160 -f small "Initialize Vault"
docker exec vault_container vault operator init > temp.txt

rm -rf .vault_howardeiner
mkdir .vault_howardeiner

grep  "Unseal Key 1\: \(\.*\)" temp.txt | cut -d: -f2 | xargs > .vault_howardeiner/unsealkey_1
grep  "Unseal Key 2\: \(\.*\)" temp.txt | cut -d: -f2 | xargs > .vault_howardeiner/unsealkey_2
grep  "Unseal Key 3\: \(\.*\)" temp.txt | cut -d: -f2 | xargs > .vault_howardeiner/unsealkey_3
grep  "Unseal Key 4\: \(\.*\)" temp.txt | cut -d: -f2 | xargs > .vault_howardeiner/unsealkey_4
grep  "Unseal Key 5\: \(\.*\)" temp.txt | cut -d: -f2 | xargs > .vault_howardeiner/unsealkey_5

grep  "Initial Root Token\: \(\.*\)" temp.txt | cut -d: -f2 | xargs > .vault_howardeiner/root_token

rm temp.txt

figlet -w 160 -f small "Unseal Vault"
docker exec vault_container vault operator unseal $(<.vault_howardeiner/unsealkey_1) > /dev/null
docker exec vault_container vault operator unseal $(<.vault_howardeiner/unsealkey_2) > /dev/null
docker exec vault_container vault operator unseal $(<.vault_howardeiner/unsealkey_3) > /dev/null

figlet -w 160 -f small "Create Vault Environment Registries"
docker exec vault_container vault login $(<.vault_howardeiner/root_token) > /dev/null
docker exec vault_container vault secrets enable -version=2 -path=ENVIRONMENTS kv > /dev/null

figlet -w 160 -f small "Store Vault Secrets in S3"
aws s3 rb s3://zipster-aws-on-demand-vault --force
aws s3 mb s3://zipster-aws-on-demand-vault
aws s3 cp .vault_howardeiner s3://zipster-aws-on-demand-vault --recursive
rm -rf .vault

figlet -w 160 -f small "Commit and Push to DockerHub"
docker rmi -f howarddeiner/zipster-aws-on-demand-vault
docker stop vault_container
docker login
docker commit vault_container howarddeiner/zipster-aws-on-demand-vault
docker push howarddeiner/zipster-aws-on-demand-vault

figlet -w 160 -f small "Bring down Local Vault Container"
docker-compose -f ../../iac/docker-compose/create_vault.yml down

rm -rf .vault_howardeiner

figlet -w 160 -f small "Save Vault Volumes to S3"
docker run --rm -v dockercompose_vault_files:/volume -v $PWD:/backup alpine tar -cjf /backup/vault_files.tar.bz2 -C /volume ./
aws s3 cp vault_files.tar.bz2 s3://zipster-aws-on-demand-vault
sudo -S <<< "password" rm -rf vault_files.tar.bz2
docker volume rm dockercompose_vault_files -f

docker run --rm -v dockercompose_vault_logs:/volume -v $PWD:/backup alpine tar -cjf /backup/vault_logs.tar.bz2 -C /volume ./
aws s3 cp vault_logs.tar.bz2 s3://zipster-aws-on-demand-vault
sudo -S <<< "password" rm -rf vault_logs.tar.bz2
docker volume rm dockercompose_vault_logs -f
