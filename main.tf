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

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-service-sg"
    Environment = "${var.app_environment}"
  }
}


resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "foo" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}