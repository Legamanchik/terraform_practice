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
  region = "us-east-1"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-terraform-ansible"
  }
}

resource "aws_subnet" "main-subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "main-subnet"
  }
}
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}
resource "aws_key_pair" "ssh-key-tf" {
   key_name = "test-key"
   public_key = tls_private_key.ssh-key.public_key_openssh
}
resource "local_file" "ssh-key-tf" {
  filename = "test-key"
  content = tls_private_key.ssh-key.private_key_pem
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "main-sg" {
  name   = "sg"
  vpc_id = aws_vpc.main.id

  ingress  {
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    from_port         = 80
  }
  ingress {
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    from_port         = 22
  }
  egress {
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    from_port         = 0
  }
}


resource "aws_instance" "main-instance-1" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main-subnet.id
  vpc_security_group_ids = ["${aws_security_group.main-sg.id}"]
  associate_public_ip_address = "true"
  key_name = "test-key"
  tags = {
    Name = "instance-main"
  }
}
