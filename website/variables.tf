variable "website_ami" {
  type        = string
  description = "The Website AMI."
  default     = "ami-1234567890"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID."
  default     = "vpc-1234567890"
}

variable "public_subnet_a_id" {
  type        = string
  description = "The public subnet A ID."
  default     = "subnet-1234567890"
}

variable "public_subnet_b_id" {
  type        = string
  description = "The public subnet B ID."
  default     = "subnet-1234567890"
}

variable "public_subnet_c_id" {
  type        = string
  description = "The public subnet C ID."
  default     = "subnet-1234567890"
}

variable "ssl_certificate_id" {
  type        = string
  description = "The SSL certificate ID."
  default     = "arn:aws:acm:eu-central-1:1234567890:certificate/1234567890"
}
