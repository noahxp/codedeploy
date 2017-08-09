#!/bin/sh

GetValue (){
	 grep $1 | awk -F ":" '{print $2}' | sed -e s/,//g -e s/" "//g -e s/\"//g
}

ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document | GetValue region`

AutoScalingGroupName=`aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $ID | GetValue AutoScalingGroupName`

Result=0

for((i=1 ; i<=300 ; i++))
do
	if [ $Result -eq 0 ];then
		sleep 1
		Result=`curl --max-time 10 -s http://localhost/monitor/check.jsp | grep -c Hello`
	else
		break
	fi
done

if [ $Result -eq 0 ];then
	echo -e "\nAbort! Wait 300 seconds for Verify Tomcat Service"
	aws autoscaling exit-standby --region $REGION --instance-ids $ID --auto-scaling-group-name $AutoScalingGroupName
	aws autoscaling resume-processes --region $REGION --auto-scaling-group-name $AutoScalingGroupName --scaling-processes AlarmNotification
	exit 1
fi
