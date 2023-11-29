terraform {
  backend "s3" {
    bucket = "backend-storagetf"
    dynamodb_table = "tf-state-lock-dynamo"
    encrypt = false
    key    = "path/path/terraform-tf-ec2-statefile"
    region = "us-east-1"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-vpc"
    Environment = "${var.app_environment}"
  }
}

# Internet gateway connected to vpc
resource "aws_internet_gateway" "aws-igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-igw"
    Environment = "${var.app_environment}"
  }
}

#Public subnet to give access to the Public
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.7.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-publicsubnet"
    Environment = "${var.app_environment}"
  }
}

#Private Subnet to house the resource
resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.0.8.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-privatesubnet"
    Environment = "${var.app_environment}"
  }
}


#Route Table to Route the Traffic from Everywhere to Internet gateway
resource "aws_route_table" "table" {
  vpc_id = "${aws_vpc.vpc.id}"
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aws-igw.id}"
  }
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-routing-table-public"
    Environment = "${var.app_environment}"
  }
}

#Attach Route Table to Public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}" 
  route_table_id = "${aws_route_table.table.id}"
}


#Security Group for the vpc
resource "aws_security_group" "service_security_group" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

/*resource "aws_security_group" "load_balancer_security_group" {
  name        = "${var.app_name}-${var.app_environment}-loadbalancersg"
  description = "Security group for the load balancer"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}*/

/*tags = {
    Name        = "${var.app_name}-${var.app_environment}-service-sg"
    Environment = "${var.app_environment}"
  }
}*/

resource "aws_instance" "ec2-instance" {
  ami = "ami-08662cc7aed840314"
  instance_type = var.instance_type
  key_name = var.instance_keypair
  vpc_security_group_ids = ["${aws_security_group.ec2-sec.id}"]
  subnet_id = aws_subnet.private.id
  iam_instance_profile = aws_iam_role.cloudwatch.name
  associate_public_ip_address = true
  tags = {
    "Name" = var.instance_name
  }
  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.diskvolume}"
    encrypted = true
  }
  
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = var.private_key
    host = aws_instance.ec2-instance.public_ip
  }
  
  // EC2 Instance Connect configuration
  metadata_options {
    http_endpoint = "enabled"
    http_put_response_hop_limit = 1
    http_tokens = "required"
  }
}
data "aws_instance" "ec2-instance" {
  instance_id = aws_instance.ec2-instance.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
 
resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-key-pair"
  public_key = tls_private_key.private_key.public_key_openssh
}

#security group for ec2 instance
resource "aws_security_group" "ec2-sec" {
  name        = "${var.app_name}-${var.app_environment}-ec2-security-name"
  description = "created using terraform"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description      = "All traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.app_environment}-ec2-security-name"
  }
}

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
  name = "ec2-cloudwatch"
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
  name = "ec2-cloudwatch"
}

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

resource "aws_sns_topic" "user_updates" {
  name = "${var.app_name}-${var.app_environment}-cloudwatch-sns"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "${var.email}"
}
