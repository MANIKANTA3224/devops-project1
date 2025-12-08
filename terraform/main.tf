######################################
# 1. Security Group
######################################
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

######################################
# 2. Key Pair
######################################
resource "aws_key_pair" "main_key" {
  key_name   = var.key_name
  public_key = file("${path.module}/id_rsa.pub")
}

######################################
# 3. EC2 Instance (UBUNTU)
######################################
resource "aws_instance" "web" {
  ami           = "ami-00d8fc944fb171e29"  # ✅ Ubuntu AMI
  instance_type = var.instance_type
  key_name      = aws_key_pair.main_key.key_name

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  tags = {
    Name = "DevOps-Final-Project-Ubuntu"
  }
}
