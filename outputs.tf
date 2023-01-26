output "update_kubectl_command" {
  description = "AWS CLI command to update kubectl config"
  value       = "aws eks update-kubeconfig --name dev-cluster --region us-east-1"
}
