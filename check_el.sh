#!/bin/bash

declare WORKING_DIR="/bla/bla/"
cd $WORKING_DIR || { echo "Failure"; exit 1; }

declare -A CORSI=( [706]="PD" [704]="IS"  [700]="FIA" [723]="IUM" 
		   [757]="AL" [766]="SIM" [758]="CS"  [761]="GI" 
		   [765]="SIC" [792]="ETC") 
declare -a CHATS=("@notificheelearning")

declare JSON_DIR="./json_diff/"
declare MOODLE_TOKEN_PATH="./moodle_token.txt"
declare BOT_TOKEN="$(<./bot_token.txt)" #Telegram bot token

declare NOW=$(date '+%Y_%m_%d__%H_%M_%S') 
declare MESSAGE="*[%s]* Aggiornata la pagina del corso su [e-learning](http://elearning.informatica.unisa.it/el-platform/course/view.php?id=%d)"


[ -d "$JSON_DIR" ] || mkdir "$JSON_DIR" #create dir if not exists

for id in "${!CORSI[@]}"
do		
    #get json from moodle
	OUTPUT=$(curl --silent\
		      --fail\
		      --data "wstoken=$(<${MOODLE_TOKEN_PATH})&wsfunction=core_course_get_contents&courseid=${id}&moodlewsrestformat=json"\
		 "http://elearning.informatica.unisa.it/el-platform/webservice/rest/server.php")

    #skip on moodle exception
	if [[ $? -ne 0 ||  "$OUTPUT" == *"webservice_access_exception"* ]];
	then
		echo "Errore" >&2
		continue
	fi

    #compare latest json with given curl output
	touch "${JSON_DIR}/${CORSI[$id]}.json"
	diff "${JSON_DIR}/${CORSI[$id]}.json" <(echo "$OUTPUT")

	if [ $? -eq 1 ] #output != latest json
	then
        #token may be expired. Get a new one if that's the case
		if [[ ${OUTPUT} == *"Token non valido"* ]]; then
			./get_token.sh
			continue
		fi

		#change name to latest saved json
		mv ${JSON_DIR}/${CORSI[$id]}.json ${JSON_DIR}/${CORSI[$id]}${NOW}.json
		#save latest output
		echo "$OUTPUT">"${JSON_DIR}/${CORSI[$id]}.json"

		#notify telegram
		declare formatted_message
		printf -v formatted_message "${MESSAGE}" "${CORSI[$id]}" $id
		for chat in ${CHATS[*]}
		do
			curl -X POST \
			     -H 'Content-Type: application/json'  \
			     -d "{\"chat_id\": \"${chat}\", \"parse_mode\": \"Markdown\", \"text\": \"${formatted_message}\"}" \
			     https://api.telegram.org/bot${BOT_TOKEN}/sendMessage
		done
	fi
done