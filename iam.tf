# Cluster Role
data "aws_iam_policy_document" "cluster_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dev_cluster_role" {
  name               = "dev-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_trust_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
}

# Cluster Node Group Role
data "aws_iam_policy_document" "node_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dev_cluster_node_role" {
  name               = "dev-cluster-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_trust_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

# Service Account Role
data "aws_iam_policy_document" "service_account_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.cluster_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "service_account_role" {
  name               = "dev-cluster-service-account-role"
  assume_role_policy = data.aws_iam_policy_document.service_account_trust_policy.json
}
