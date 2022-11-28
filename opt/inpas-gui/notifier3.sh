#!/bin/bash

# this script asks for card id and job name when requested by inpas3 cups backend
# must be executed in user context on every login
# requires: java


BASEDIR=$(dirname "$(readlink -f "$0")")

while true; do
	sleep 1
	if [ -f /tmp/printjob/status ]; then
		KILLPID=$(ps aux | grep "java -jar $BASEDIR/PrintWaitMessage.jar" | grep -v grep | awk '{print $2}')

		if grep -q "need-parameter" /tmp/printjob/status; then
			LOOP=1
			while [ "$LOOP" == "1" ]; do
				RESULT=$(zenity --forms \
				         --title="Neuer Druckauftrag mit Kopierkarte" \
				         --text="Bitte geben Sie Ihre Kopierkarten-Nummer ein.\nAn unseren Druckstationen können Sie Ihre Dateien während\nder Öffnungszeiten selbsständig ausdrucken.\n\nZur Wiedererkennung Ihres Druckauftrages können Sie\neinen Auftragsnamen vergeben." \
				         --add-entry="Kartennummer" \
				         --add-entry="Auftragsname")
				echo $RESULT | cut -d"|" -f1 > /tmp/printjob/card-id
		 		echo $RESULT | cut -d"|" -f2 > /tmp/printjob/job-name
				if [ "$(cat /tmp/printjob/card-id)" == "" ] || [[ "$(cat /tmp/printjob/card-id)" =~ ^[0-9]+$ ]]; then
					if [ "$(cat /tmp/printjob/job-name)" != "" ] && [[ ! "$(cat /tmp/printjob/job-name)" =~ ^[0-9a-zA-Z_]+$ ]]; then
						zenity --info --title="Eingabefehler" --text="Ungültiger Auftragsname, bitte nur Ziffern und\nBuchstaben (A-Z) eintragen oder den Namen leer lassen."
					else
						LOOP="0"
					fi
				else
					zenity --info --title="Eingabefehler" --text="Ungültige Kartennummer, bitte erneut eingeben."
				fi
			done
			echo "set-parameter" > /tmp/printjob/status
		fi

		if grep -q "sending" /tmp/printjob/status || grep -q "set-parameter" /tmp/printjob/status; then
			if [ "$KILLPID" == "" ]; then
					# this java program just displays a simple window with text and an endless loading bar (until killed through this script)
					# it has no functionality except showing the user that the process is still running, so that he waits until job is sent before going to the printer
					java -jar "$BASEDIR/PrintWaitMessage.jar" &
			fi
		fi

		if grep -q "done" /tmp/printjob/status; then
			if [ "$KILLPID" != "" ]; then
				kill $KILLPID
				rm /tmp/printjob/status
			fi
		fi
	fi
done
