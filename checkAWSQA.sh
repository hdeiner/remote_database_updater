#!/bin/bash

if python3 remote_database_updater.py -f awsqa_mysql.csv
then
echo "AWSQA environment is good"
else
echo "AWSQA environment is NOT good"
fi
