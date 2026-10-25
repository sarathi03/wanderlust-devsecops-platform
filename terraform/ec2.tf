resource "aws_key_pair" "deployer" {
  key_name   = "wanderlust-deployer-key"
  public_key = file(pathexpand(var.public_key_path))
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "wanderlust" {
  name        = "wanderlust-ec2-sg"
  description = "Security group for Wanderlust EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from user's trusted IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wanderlust-ec2-sg"
  }
}

resource "aws_instance" "wanderlust" {
  ami                    = var.ami_id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.deployer.key_name
  vpc_security_group_ids  = [aws_security_group.wanderlust.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "wanderlust"
  }
}
