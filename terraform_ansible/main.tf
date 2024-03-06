terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.default_region
}
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}
resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main.id
}
resource "aws_subnet" "main-subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, 1)
  tags = {
    Name = "main-subnet"
  }
}
resource "aws_route_table" "main-table" {
  vpc_id = aws_vpc.main.id

  route {

  cidr_block = var.cidr_block
  gateway_id = aws_internet_gateway.main_gw.id

  }
}
resource "aws_route_table_association" "main-association" {

  subnet_id = aws_subnet.main-subnet.id
  route_table_id = aws_route_table.main-table.id

}
resource "tls_private_key" "key_tf" {
  algorithm = "RSA"
  rsa_bits = 4096
}
resource "aws_key_pair" "tf-key" {
   key_name = var.key_name
   public_key = tls_private_key.key_tf.public_key_openssh
}
resource "local_file" "tf-key" {
  filename = "tf-key.pem"
  content = tls_private_key.key_tf.private_key_pem
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter{
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
  
}

resource "aws_security_group" "main-sg" {
  name   = "sg"
  vpc_id = aws_vpc.main.id

  ingress {
    cidr_blocks = [
      var.cidr_block
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      var.cidr_block
    ]
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }
  egress {
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = var.cidr_blocks
    from_port         = 0
  }
  depends_on = [ aws_vpc.main ]
}


resource "aws_instance" "main-instance-1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.default_instance_type
  subnet_id     = aws_subnet.main-subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = ["${aws_security_group.main-sg.id}"]
  key_name = var.key_name
  tags = {
    Name = "instance-main"
  }
}
