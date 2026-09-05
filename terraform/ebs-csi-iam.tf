# =============================================================
# WORKLOAD EKS - EBS CSI POD IDENTITY
# =============================================================

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "ebs-csi-pod-identity"

  attach_aws_ebs_csi_policy = true

  associations = {
    ebs_csi = {
      cluster_name    = module.workload_eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "ebs-csi-pod-identity"
    }
  )
}