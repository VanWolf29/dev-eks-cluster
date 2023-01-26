resource "aws_eks_cluster" "dev_cluster" {
  name     = "dev-cluster"
  role_arn = aws_iam_role.dev_cluster_role.arn
  version  = "1.24"

  vpc_config {
    subnet_ids              = aws_subnet.public_subnets[*].id
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  tags = {
    Name = "dev-cluster"
  }

  depends_on = [
    aws_iam_role.dev_cluster_role
  ]
}

data "tls_certificate" "cluster_certificate" {
  url = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster_certificate.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.cluster_certificate.url
}

resource "aws_eks_node_group" "dev_cluster_node_group" {
  cluster_name    = aws_eks_cluster.dev_cluster.name
  node_group_name = "dev-cluster-node-group"
  node_role_arn   = aws_iam_role.dev_cluster_node_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  tags = {
    Name = "dev-cluster-node-group"
  }

  depends_on = [
    aws_iam_role.dev_cluster_node_role
  ]
}
