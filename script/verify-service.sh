#!/bin/sh

status=""
for number in {1..30}
do
	# result=`curl --max-time 10 -s http://localhost/ | grep -c Hello`
	status=`sudo /etc/init.d/httpd status |grep -c "running"`
	if [ $status -eq 1 ];then
		echo 'service check final. result=' $status
		break
	fi
	sleep 1
done
