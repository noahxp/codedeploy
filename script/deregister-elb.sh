#!/bin/bash

set -e

export INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
export REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | grep -i region | awk -F\" '{print $4}')
export ASGNAME=$(aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $INSTANCE_ID | grep -i AutoScalingGroupName | awk -F\" '{print $4}' )

export MINSIZE=$(aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $ASGNAME | grep -i MinSize | awk -F: '{print $2}' | awk -F, '{print $1}' | xargs )
export NEWSIZE=$(($MINSIZE-1))


if [ $MINSIZE -lt 1 ];then
	echo "auto-scaling-group MinSize must be gather than 0."
	. $(dirname $0)/resume-scaling.sh
	exit 1
fi


# check ec2 is InService
export status=$(aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $INSTANCE_ID |grep -i LifecycleState|awk -F\" '{print $4}')
if [ "$status" != "InService" ]; then
	echo "ec2 is not InService: $INSTANCE_ID ($status)"
	exit 0
fi

# ec2 min-size -1
aws autoscaling update-auto-scaling-group --region $REGION --auto-scaling-group-name $ASGNAME --min-size $NEWSIZE

# ec2 enter standby
aws autoscaling enter-standby --region $REGION --instance-ids $INSTANCE_ID --auto-scaling-group-name $ASGNAME --should-decrement-desired-capacity


export status=""
for number in {1..300}
do
	export status=$(aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $INSTANCE_ID |grep -i LifecycleState |awk -F\" '{print $4}')
	# -z is when condition null return true , -n is not null reutrn true.
	# if [[ -n $status ]];then
	if [ "$status" == "Standby" ]; then
		break
	fi
	sleep 1
done




if [ "$status" != "Standby" ]; then
	# ec2 min-size restore to default
	aws autoscaling update-auto-scaling-group --region $REGION --auto-scaling-group-name $ASGNAME --min-size $MINSIZE

	echo "ec2 enter-standby failure. $(aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $INSTANCE_ID)"
	exit 1
else
	echo "ec2 enter-standby success."
	exit 0
fi
