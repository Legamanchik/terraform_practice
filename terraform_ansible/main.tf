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
}

resource "aws_security_group_rule" "allow_outbount" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_security_group.main-sg.id
}
resource "aws_security_group_rule" "allow_inbound" {
  type              = "ingress"
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  security_group_id = aws_security_group.main-sg.id
}

resource "aws_security_group" "sg-for-ssh" {
  name   = "sg_ssh"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  security_group_id = aws_security_group.sg-for-ssh.id
}

resource "aws_instance" "main-instance-1" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main-subnet.id
  vpc_security_group_ids = ["${aws_security_group.main-sg.id}", "${aws_security_group.sg-for-ssh.id}"]
  associate_public_ip_address = "true"
  tags = {
    Name = "instance-main"
  }
}
