resource "aws_efs_file_system" "efs" {
  creation_token = "efs1"
  encrypted      = true

 
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id        = aws_efs_file_system.efs.id
  subnet_id             = aws_subnet.private.id
  security_groups      = [aws_security_group.efs.id]
}



resource "aws_security_group" "efs" {
  name        = "${var.app_name}-${var.app_environment}-efs-security-name"
  description = "created using terraform"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    description      = "All traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    security_groups = [aws_security_group.ec2-sec.id] 
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.app_environment}-efs-security-name"
  }
}

