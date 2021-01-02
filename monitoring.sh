#!/bin/bash
log=/web/sites/www.itstroi.ru/log/ssl-access.log	# Our access log file
X=10
Y=5
lockfile=lock
msg=message.txt
count=count.txt
email=root
tempfile=temp
# Set noclobber
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
	then
	trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
	echo "Script is running"
	if [ -f $tempfile ]
		then nextcount=$(( `cat $count` + 1))	# Old count + 1 for next run
		olddate=$(cat $tempfile)
		echo "Информация актуальна с $olddate до `date`:" > $msg
		else nextcount=0        # This is the first run of script, then nextcount=0
		echo "Информация актуальна с самого начала до `date`:" > $msg
		fi
	# Function for repeated comands
	function readinglog {
	cat $log | tail -n +$nextcount
	}		
	# 1st task.
	echo "1. X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта:" >> $msg
	readinglog | awk '{print $1}' | uniq -c | sort -n | tac | head -n $X | cat -n >> $msg
	# 2nd task.
	echo "2. Y запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта:" >> $msg
	readinglog | awk '{print $7}' | uniq -c | sort -n | tac | head -n $Y | cat -n >> $msg
	# 3rd task.
	echo "3. Все ошибки c момента последнего запуска скрипта:" >> $msg
	readinglog | awk '$9>400' | sort | cat -n >> $msg
	# 4th task.
	readinglog | awk '{print $9}' | sort | cat -n > codes.txt
	echo "4. Cписок всех кодов возврата с указанием их кол-ва с момента последнего запуска прикреплен к письму в файле codes.txt, количество кодов: `wc -l codes.txt | awk '{print $1}'`" >> $msg
	# Sending to by e-mail
	cat $msg | mail -s "Web monitoring" -a codes.txt $email
	rm -f codes.txt 2> /dev/null	
	date>$tempfile
	cat $log | wc -l > count.txt
	sleep 5
	echo "Script finished"
else
	echo "Failed to acquire lockfile: $lockfile."
	echo "Held by process with ID: $(cat $lockfile)"
fi
