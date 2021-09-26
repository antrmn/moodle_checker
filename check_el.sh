#!/bin/bash

declare -A CORSI=( [696]="PrA" [706]="PD" [704]="IS" [700]="FIA" [701]="MP" [697]="Fisica") 
#declare -A CHATS=("@notificheelearning" "-1001363598092")
declare -a CHATS=("@notificheelearning")

declare JSON_DIR="./json_diff/"
declare MOODLE_TOKEN_PATH="./moodle_token.txt"
declare BOT_TOKEN="$(<./bot_token.txt)"

declare NOW=$(date '+%Y_%m_%d__%H_%M_%S') 
declare MESSAGE="*[%s]* Aggiornata la pagina del corso su [e-learning](http://elearning.informatica.unisa.it/el-platform/course/view.php?id=%d)"


[ -d "$JSON_DIR" ] || mkdir "$JSON_DIR"

for id in "${!CORSI[@]}"
do		
	OUTPUT=$(curl --silent\
		      --fail\
		      --data "wstoken=$(<${MOODLE_TOKEN_PATH})&wsfunction=core_course_get_contents&courseid=${id}&moodlewsrestformat=json"\
		 "http://elearning.informatica.unisa.it/el-platform/webservice/rest/server.php")

	if [ $? -ne 0 ]
	then
		continue
	fi
	
	touch "${JSON_DIR}/${CORSI[$id]}.json"
	diff "${JSON_DIR}/${CORSI[$id]}.json" <(echo "$OUTPUT")
	if [ $? -eq 1 ]
	then
		if [[ ${OUTPUT} == *"Token non valido"* ]]; then
			./get_token.sh
			continue
		fi

		mv ${JSON_DIR}/${CORSI[$id]}.json ${JSON_DIR}/${CORSI[$id]}${NOW}.json
		echo "$OUTPUT">"${JSON_DIR}/${CORSI[$id]}.json"

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
