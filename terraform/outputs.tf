# =============================================================
# ECR
# =============================================================
output "frontend_image_url" {
  description = "Logbeacon frontend image url"
  value       = module.ecr_frontend.repository_url
}

output "backend_image_url" {
  description = "Logbeacon backend image url"
  value       = module.ecr_backend.repository_url
}


# =============================================================
# MANAGEMENT CLUSTER
# =============================================================

output "management_cluster_name" {
  description = "Management EKS cluster name"
  value       = module.management_eks.cluster_name
}

output "management_cluster_arn" {
  description = "Management EKS cluster ARN"
  value       = module.management_eks.cluster_arn
}

output "management_cluster_endpoint" {
  description = "Management EKS Kubernetes API endpoint"
  value       = module.management_eks.cluster_endpoint
}

output "management_cluster_certificate_authority_data" {
  description = "Management EKS cluster CA certificate"
  value       = module.management_eks.cluster_certificate_authority_data
  sensitive   = true
}


# =============================================================
# WORKLOAD CLUSTER
# =============================================================

output "workload_cluster_name" {
  description = "Workload EKS cluster name"
  value       = module.workload_eks.cluster_name
}

output "workload_cluster_arn" {
  description = "Workload EKS cluster ARN"
  value       = module.workload_eks.cluster_arn
}

output "workload_cluster_endpoint" {
  description = "Workload EKS Kubernetes API endpoint"
  value       = module.workload_eks.cluster_endpoint
}

output "workload_cluster_certificate_authority_data" {
  description = "Workload EKS cluster CA certificate"
  value       = module.workload_eks.cluster_certificate_authority_data
  sensitive   = true
}