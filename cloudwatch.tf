resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
     alarm_name                = "cpu-utilization"
     comparison_operator       = "GreaterThanOrEqualToThreshold"
     evaluation_periods        = "1"
     metric_name               = "CPUUtilization"
     namespace                 = "AWS/EC2"
     period                    = "120" #seconds
     statistic                 = "Average"
     threshold                 = "60"
     alarm_description         = "This metric monitors ec2 cpu utilization"
     alarm_actions             = [aws_sns_topic.user_updates.arn]
     insufficient_data_actions = []
     treat_missing_data = "notBreaching"

dimensions = {
       InstanceId = aws_instance.ec2-instance.id
     }
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk" {
  alarm_name                = "disk-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  #namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "70"
  alarm_description         = "This metric monitors ec2 disk utilization"
  actions_enabled           = "true"
  #alarm_actions             = ["arn:aws:sns:ap-south-1:269763233488:Default_CloudWatch_Alarms_Topic"]
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.user_updates.arn]
  treat_missing_data = "notBreaching"

   dimensions = {
    path = "/"
    InstanceId = aws_instance.ec2-instance.id
    device = "xvda1"
    fstype = "ext4"
   
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_mem" {
  alarm_name                = "memory-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "mem_used_percent"
  namespace                 = "CWAgent"
  #namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors ec2 disk utilization"
  actions_enabled           = "true"
  #alarm_actions             = ["arn:aws:sns:ap-south-1:269763233488:Default_CloudWatch_Alarms_Topic"]
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.user_updates.arn]
  treat_missing_data = "notBreaching"

   dimensions = {
    InstanceId = aws_instance.ec2-instance.id  
  }

}
