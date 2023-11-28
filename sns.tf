resource "aws_sns_topic" "user_updates" {
  name = "${var.app_name}-${var.app_environment}-cloudwatch-sns"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "${var.email}"
}