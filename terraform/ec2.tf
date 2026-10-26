# Jenkins master and Jenkins worker EC2 instances in the default VPC.
# The EKS cluster is NOT created here; it is created with eksctl (eks/cluster.yaml).

# Latest official Ubuntu 24.04 LTS image for the selected region (no hardcoded AMI IDs).
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "wanderlust" {
  key_name   = "wanderlust-key"
  public_key = file(pathexpand(var.public_key_path))
}

# ---------- Jenkins master: SSH, Jenkins UI (8080), SonarQube UI (9000) from your IP ----------
resource "aws_security_group" "master" {
  name        = "wanderlust-jenkins-master-sg"
  description = "Jenkins master and SonarQube"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "SonarQube UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wanderlust-jenkins-master-sg", project = "wanderlust" }
}

# ---------- Jenkins worker: SSH from the master (agent connection) and from your IP ----------
resource "aws_security_group" "worker" {
  name        = "wanderlust-jenkins-worker-sg"
  description = "Jenkins build agent"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "SSH from Jenkins master (agent launch)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.master.id]
  }

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wanderlust-jenkins-worker-sg", project = "wanderlust" }
}

resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  key_name               = aws_key_pair.wanderlust.key_name
  vpc_security_group_ids = [aws_security_group.master.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "wanderlust-jenkins-master", project = "wanderlust" }
}

resource "aws_instance" "worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.wanderlust.key_name
  vpc_security_group_ids = [aws_security_group.worker.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "wanderlust-jenkins-worker", project = "wanderlust" }
}
