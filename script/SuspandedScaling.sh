#!/bin/sh

GetValue (){
	 grep $1 | awk -F ":" '{print $2}' | sed -e s/,//g -e s/" "//g -e s/\"//g
}

ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document | GetValue region`

AutoScalingGroupName=`aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $ID | GetValue AutoScalingGroupName`
AutoScalingDesiredCapacity=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue DesiredCapacity`

###
echo ">>> Suspand AlarmNotification <<<"
aws autoscaling suspend-processes --region $REGION --auto-scaling-group-name $AutoScalingGroupName --scaling-processes AlarmNotification

###
echo -n "Verify AlarmNotification Suspanded"
Suspanded_Status=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue ProcessName`

for((i=1 ; i<=60 ; i++))
do
	if [ -z $Suspanded_Status ] || [ $Suspanded_Status != "AlarmNotification" ];then
		sleep 1
		Suspanded_Status=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue ProcessName`
	else
		echo " ...OK"
		break
	fi
done

if [ -z $Suspanded_Status ] || [ $Suspanded_Status != "AlarmNotification" ];then
	echo -e "\nAbort! Wait 60 seconds for Suspanded AlarmNotification"
	exit 1
fi
