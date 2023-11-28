resource "aws_iam_role_policy_attachment" "cloudwatch" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",

  ])

  role       = aws_iam_role.cloudwatch.name
  policy_arn = each.value
}

resource "aws_iam_role" "cloudwatch" {
  name = "${var.app_name}-${var.app_environment}-cloudwatch"
  description = "EC2 IAM role for cloudwatch agent"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
   
EOF
}

resource "aws_iam_instance_profile" "cloudwatch" {
  role = aws_iam_role.cloudwatch.name
  name = "${var.app_name}-${var.app_environment}-cloudwatch"
}