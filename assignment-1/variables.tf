variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "my_ip" {
  description = "Your public IP in CIDR format (e.g. 203.0.113.45/32)"
  type        = string
  default     = "3.93.67.6/32"
}

variable "bucket_name" {
  type    = string
  default = "credit-saison-assignment-test"
}
