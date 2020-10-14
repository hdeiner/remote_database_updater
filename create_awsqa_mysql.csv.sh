#!/bin/bash

echo 'sql_runner_host,sql_runner_userid,sql_runner_password,database_type,database_host,database_userid,database_password,port,database,sql_script_to_run' > awsqa_mysql.csv
echo $1',ubuntu,,MySQL,'$1',root,password,3306,zipster,environment_creators/src/sql/V1_1__Zipcode_Schema.sql' >> awsqa_mysql.csv
echo $1',ubuntu,,MySQL,'$1',root,password,3306,zipster,environment_creators/src/sql/V1_2__Zipcode_Static_Data.sql' >> awsqa_mysql.csv
echo $1',ubuntu,,MySQL,'$1',root,password,3306,zipster,environment_creators/src/sql/V2_1__Add_Spatial_Data.sql' >> awsqa_mysql.csv
echo $1',ubuntu,,MySQL,'$1',root,password,3306,zipster,environment_creators/src/sql/V3_1__Zipcode_Test_Data.sql' >> awsqa_mysql.csv
