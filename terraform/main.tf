##########################################
# Terraform Backend (S3 Only – No DynamoDB)
##########################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "devops-tfstate-bucket-manikanta"      # YOUR S3 BUCKET NAME
    key    = "ec2-project/terraform.tfstate"     # STATE FILE PATH IN BUCKET
    region = "ap-southeast-1"                    # UPDATED REGION
    encrypt = true
  }
}

##########################################
# Provider
##########################################
provider "aws" {
  region = "ap-southeast-1"   # UPDATED REGION
}

##########################################
# Security Group
##########################################
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP & SSH"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##########################################
# Key Pair (using existing public key)
##########################################
resource "aws_key_pair" "main_key" {
  key_name   = "devops-key"
  public_key = file("${path.module}/id_rsa.pub")
}

##########################################
# EC2 Instance
##########################################
resource "aws_instance" "web_server" {
  ami           = "ami-00d8fc944fb171e29"   # Ubuntu 22.04 for ap-southeast-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main_key.key_name

  security_groups = [
    aws_security_group.web_sg.name
  ]

  tags = {
    Name = "devops-web-server"
  }
}

##########################################
# Outputs
##########################################
output "public_ip" {
  value = aws_instance.web_server.public_ip
}

output "public_dns" {
  value = aws_instance.web_server.public_dns
}
