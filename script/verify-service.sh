#!/bin/bash

status=""
for number in {1..30}
do
	# result=`curl --max-time 10 -s http://localhost/ | grep -c Hello`
	export status=`/bin/systemctl status httpd.service |grep -c "running"`
	if [ $status -eq 1 ];then
		break
	fi
	sleep 1
done


if [ $status -eq 1 ];then
	echo 'verify-service success'
	exit 0
else
	echo 'verify-service failure'
	exit 1
fi
