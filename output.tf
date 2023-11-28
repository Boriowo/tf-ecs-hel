output "InstanceId" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2-instance.id
}
