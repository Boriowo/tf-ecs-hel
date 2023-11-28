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

variable "instance_type" {
    description = "EC2 Instnace Type"
    type = string
    default = "m5.large"
}

variable "private_key" {
    description = "Private key for SSH connection"
    default     = ""
}

variable "diskvolume" {
    description = "EC2 instance disk size in GB. Put numerical value"
    type = string
    default = "1024"
}