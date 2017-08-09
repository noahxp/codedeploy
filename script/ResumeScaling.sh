#!/bin/sh

GetValue (){

	 grep $1 | awk -F ":" '{print $2}' | sed -e s/,//g -e s/" "//g -e s/\"//g

}

ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document | GetValue region`

AutoScalingGroupName=`aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $ID | GetValue AutoScalingGroupName`

Suspanded_Status=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue ProcessName`

###

if [ $Suspanded_Status == "AlarmNotification" ];then

	echo ">>> Resume AlarmNotification <<<"

	aws autoscaling resume-processes --region $REGION --auto-scaling-group-name $AutoScalingGroupName --scaling-processes AlarmNotification

	###
	echo -n "Verify AlarmNotification Resume"

	Resume_Status=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue ProcessName`

	for((i=1 ; i<=60 ; i++))
	do

		if [ ! -z $Resume_Status ];then
			sleep 1
			Resume_Status=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue ProcessName`
		else
			echo " ...OK"
			break
		fi

	done

	if [ ! -z $Resume_Status ];then
		echo -e "\nAbort! Wait 60 seconds for Resumeed AlarmNotification"
		exit 1
	fi

fi

