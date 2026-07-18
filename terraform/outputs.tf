output "instance_id" {
  description = "ID of the provisioned EC2 instance."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance."
  value       = aws_instance.app.public_dns
}

output "selected_subnet_id" {
  description = "Default public subnet selected for the EC2 instance."
  value       = local.selected_subnet_id
}

output "amazon_linux_ami_id" {
  description = "Amazon Linux 2023 AMI selected dynamically."
  value       = data.aws_ami.amazon_linux_2023.id
}

output "application_url" {
  description = "HTTP URL used after the Flask container is deployed."
  value       = "http://${aws_instance.app.public_ip}"
}

output "ssh_command" {
  description = "Example SSH command using the AWS Academy PEM key."
  value       = "ssh -i /path/to/labsuser.pem ec2-user@${aws_instance.app.public_ip}"
}
