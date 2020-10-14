#!/usr/bin/env bash

figlet -w 160 -f standard "Bring All Down on Local Machine"

export VAULT_ADDRESS=http://127.0.0.1:8200
export VAULT_TOKEN=$(<.vault_howardeiner/root_token)
export ENVIRONMENT=howarddeiner

docker-compose -f ../../iac/docker-compose/use_spark.yml down
docker-compose -f ../../iac/docker-compose/use_oracle.yml down
docker-compose -f ../../iac/docker-compose/use_vault.yml down

rm -rf .vault_howardeiner
docker volume rm docker-compose_oracle_data

