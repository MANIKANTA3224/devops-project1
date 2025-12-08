##########################################
# main.tf — only resources
##########################################

# Security Group
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

# Key Pair
resource "aws_key_pair" "main_key" {
  key_name   = "devops-key"
  public_key = file("${path.module}/id_rsa.pub")
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-00d8fc944fb171e29"   # Ubuntu 22.04 ap-southeast-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main_key.key_name

  security_groups = [
    aws_security_group.web_sg.name
  ]

  tags = {
    Name = "devops-web-server"
  }
}
