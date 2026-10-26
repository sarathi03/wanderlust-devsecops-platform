output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

output "worker_private_ip" {
  description = "Use this as the Host when adding the Jenkins agent (master -> worker over the VPC)"
  value       = aws_instance.worker.private_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.master.public_ip}:8080"
}

output "sonarqube_url" {
  value = "http://${aws_instance.master.public_ip}:9000"
}
