#!/bin/bash

declare MOODLE_TOKEN_PATH="./moodle_token.txt"
declare MOODLE_USERNAME="$(<./moodle_username.txt)"
declare MOODLE_PASSWORD="$(<./moodle_password.txt)"
declare URL="http://elearning.informatica.unisa.it/el-platform/login/token.php"
declare QUERY="username=${MOODLE_USERNAME}&password=${MOODLE_PASSWORD}&service=moodle_mobile_app"

declare token=$(curl --silent --fail --data "${QUERY}" ${URL} | jq -r .token -)
if [ ${PIPESTATUS[0]} -eq 0 ] 
then
	echo ${token} > "${MOODLE_TOKEN_PATH}"
fi
