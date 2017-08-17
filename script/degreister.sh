#!/bin/bash

# Handle ASG processes
# If HANDLE_PROCS=true, the following Auto Scaling events are suspended automatically during the deployment process: AZRebalance, AlarmNotification, ScheduledActions, ReplaceUnhealthy
# reference : http://docs.aws.amazon.com/codedeploy/latest/userguide/integrations-aws-auto-scaling.html
HANDLE_PROCS=false
