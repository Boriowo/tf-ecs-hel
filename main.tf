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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

/*resource "aws_security_group" "load_balancer_security_group" {
  name        = "${var.app_name}-${var.app_environment}-loadbalancersg"
  description = "Security group for the load balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

#EC2 Instance
resource "aws_instance" "ec2-instance" {
  ami = "ami-08662cc7aed840314"
  instance_type = var.instance_type
  key_name = var.instance_keypair
  vpc_security_group_ids = ["${aws_security_group.ec2-sec.id}"]
  subnet_id             = aws_subnet.private.id
  iam_instance_profile  = aws_iam_role.cloudwatch.name
  user_data = file("${path.module}/cloudwatch-userdata.tpl")
  tags = {
    "Name" = var.instance_name
  }
   root_block_device {
    volume_type = "gp2"
    volume_size = "${var.diskvolume}"
    encrypted   = true
  } 
   
provisioner "remote-exec" {
  inline = [
    "sudo mkdir -p ${var.efs_share_path_instance_1}",
    "sudo apt-get update",
    "sudo apt-get install -y docker.io",
    "sudo apt-get install -y docker-compose",
    "sudo systemctl enable docker",
    "sudo systemctl start docker",
    "sudo mkdir -p ${var.efs_share_path_instance_1}",
    "sleep 60",
    "echo '${aws_efs_file_system.efs.dns_name}:/ ${var.efs_share_path_instance_1} nfs4 defaults,_netdev 0 0' | sudo tee -a /etc/fstab",
    "sudo mount -a",
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = self.public_ip
  }
 }
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
