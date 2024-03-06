variable "cidr_block" {
  description = "default cidr_block for any mask"
  default = "0.0.0.0/0"
  type = string
}

variable "cidr_blocks" {
  description = "default cidr_blocks for any mask"
  default = ["0.0.0.0/0"]
  type = list(string)
}

variable "cidr_block_vpc" {
  description = "cidr_block for vpc"
  default = "10.0.0.0/16"

}
variable "key_name" {
    description = "Key pair name variable"
    default = "tf-key"
}
variable "vpc_name" {
  default = "vpc-terraform-ansible"
}
variable "default_region" {
  description = "Default region for Aws"
  default = "us-east-1"
}   
variable "default_instance_type" {
  description = "Default ec2 instance type"
  default = "t2.micro"
}