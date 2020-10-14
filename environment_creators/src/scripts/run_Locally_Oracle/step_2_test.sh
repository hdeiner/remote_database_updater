#!/usr/bin/env bash

figlet -w 160 -f standard "Test Locally"
TEST_COMMAND="curl http://localhost:8080/zipster -d '{\"zipcode\":\"07440\","radius":\"2\"}'"
echo $TEST_COMMAND
eval $TEST_COMMAND
echo ""
