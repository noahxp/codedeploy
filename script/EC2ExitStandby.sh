#!/bin/sh

GetValue (){

	 grep $1 | awk -F ":" '{print $2}' | sed -e s/,//g -e s/" "//g -e s/\"//g

}

ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document | GetValue region`

AutoScalingGroupName=`aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $ID | GetValue AutoScalingGroupName`
AutoScalingMinSize=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue MinSize`

LifecycleState=`aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $ID | GetValue LifecycleState`

###

if [ $LifecycleState == "Standby" ];then

	echo ">>> Set instance $ID to InService mode <<<"

	aws autoscaling exit-standby --region $REGION --instance-ids $ID --auto-scaling-group-name $AutoScalingGroupName

	echo -n "Verify instance $ID already in InService mode"

	for((i=1 ; i<=60 ; i++))
	do

			if [ $LifecycleState != "InService" ];then
				sleep 1
				LifecycleState=`aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $ID | GetValue LifecycleState`
			else
				echo " ...OK"
				break
		fi

	done

	if [ $LifecycleState != "InService" ];then
		echo -e "\nAbort! Wait 60 seconds for set instance $ID to InService mode"
		aws autoscaling resume-processes --region $REGION --auto-scaling-group-name $AutoScalingGroupName --scaling-processes AlarmNotification
		exit 1
	fi

	###
	echo ">>> AutoScaling MinSize add 1 <<<"

	NewMinSize=`expr $AutoScalingMinSize + 1`

	aws autoscaling update-auto-scaling-group --region $REGION --auto-scaling-group-name $AutoScalingGroupName --min-size $NewMinSize

	echo -n "Verify AutoScaling MinSize add 1"

	for((i=1 ; i<=60 ; i++))
	do

		if [ $AutoScalingMinSize -ne $NewMinSize ];then
			sleep 1
			AutoScalingMinSize=`aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $AutoScalingGroupName | GetValue MinSize`
		else
			echo " ...OK"
			break
		fi

	done
	
	if [ $AutoScalingMinSize -ne $NewMinSize ];then
		echo "Abort! Fail to AutoScaling MinSize add 1"
		aws autoscaling resume-processes --region $REGION --auto-scaling-group-name $AutoScalingGroupName --scaling-processes AlarmNotification
		exit 1
	fi
	
fi

