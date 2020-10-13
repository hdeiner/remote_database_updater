#!/bin/bash

echo 'sql_runner_host,sql_runner_userid,sql_runner_password,database_host,database_userid,database_password,port,database,sql_script_to_run' > awsqa.csv
echo $1',ubuntu,,'$1',root,password,3306,zipster,environment_creators/src/sql/V1_1__Zipcode_Schema.sql' >> awsqa.csv
echo $1',ubuntu,,'$1',root,password,3306,zipster,environment_creators/src/sql/V1_2__Zipcode_Static_Data.sql' >> awsqa.csv
echo $1',ubuntu,,'$1',root,password,3306,zipster,environment_creators/src/sql/V2_1__Add_Spatial_Data.sql' >> awsqa.csv
echo $1',ubuntu,,'$1',root,password,3306,zipster,environment_creators/src/sql/V3_1__Zipcode_Test_Data.sql' >> awsqa.csv
