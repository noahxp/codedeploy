#!/bin/sh

# reference : http://docs.aws.amazon.com/autoscaling/latest/userguide/as-suspend-resume-processes.html

set -e

export INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
export REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | grep -i region | awk -F\" '{print $4}')
export ASGNAME=$(aws autoscaling describe-auto-scaling-instances --region $REGION --instance-ids $INSTANCE_ID | grep -i AutoScalingGroupName | awk -F\" '{print $4}' )

#suspend-processes
aws autoscaling suspend-processes --region $REGION --auto-scaling-group-name $ASGNAME --scaling-processes AlarmNotification
aws autoscaling suspend-processes --region $REGION --auto-scaling-group-name $ASGNAME --scaling-processes ScheduledActions


status=""
for number in {1..30}
do
	status=$(aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $ASGNAME |grep -i ProcessName|grep -i AlarmNotification)
	echo $status
  # -z, when condition is null return true , -n not null reutrn true.
	if [[ -n $status ]];then
		break
	fi
	sleep 1
done

# suspend failure
if [[ -z $status ]];then
	echo 'suspend may be failure.' $(aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names $ASGNAME)
	exit 1
else
	exit 0
fi
