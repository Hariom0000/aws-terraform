output "cluster_name" { value = aws_eks_cluster.main.name }
output "cluster_security_group_id" { value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id }

output "load_balancer_controller_role_arn" {
  value = aws_iam_role.load_balancer_controller.arn
}