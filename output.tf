output "InstanceId" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2-instance.id
}

output "private_key_pem" {
  description = "The private key data in PEM format"
  value       = tls_private_key.ec2-key-pair.private_key_pem
  sensitive   = true
}
 
output "public_key_openssh" {
  description = "The public key data in OpenSSH authorized_keys format"
  value       = tls_private_key.ec2-public-key.public_key_openssh
}
