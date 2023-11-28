variable "region" {
    type = string
    description = "Region"
    default = "us-east-1"
}

variable "app_name" {
    type        = string
    default     = "Healthelink"
}

variable "app_environment" {
    type        = string
    default     = "dev"
}

variable "instance_name" {
    description = "EC2 Instnace name"
    type = string
    default = "datahub-ec2"
}

variable "instance_type" {
    description = "EC2 Instnace Type"
    type = string
    default = "m5.large"
}

variable "instance_keypair" {
    description = "EC2 Instnace key"
    type = string
    default = ""
}

variable "private_key" {
    description = "Private key for SSH connection"
    default     = "moses.pem"
}

variable "diskvolume" {
    description = "EC2 instance disk size in GB. Put numerical value"
    type = string
    default = "1024"
}

variable "email" {
    description = "VPC ID"
    type = string
    default = "boriowo@ismiletechnologies.com"
}