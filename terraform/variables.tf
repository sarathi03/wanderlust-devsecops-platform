variable "aws_region" {
  description = "AWS region for all resources (Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "master_instance_type" {
  description = "Jenkins master + SonarQube + kubectl/eksctl/argocd CLI"
  type        = string
  default     = "t3.large"
}

variable "worker_instance_type" {
  description = "Jenkins build agent (Docker, Trivy, OWASP Dependency-Check)"
  type        = string
  default     = "t3.large"
}

variable "public_key_path" {
  description = "Path to YOUR SSH public key, used to log in to both instances"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_cidr" {
  description = "Your public IP in CIDR form (e.g. 203.0.113.10/32). Only this IP can reach SSH/Jenkins/SonarQube."
  type        = string
}
