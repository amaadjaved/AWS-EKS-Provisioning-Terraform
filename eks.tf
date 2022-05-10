provider "aws" {
 region = "eu-central-1"
 access_key = var.credentials.access_key
 secret_key = var.credentials.secret_key
 #shared_config_files      = ["$HOME/.aws/config"]
 #shared_credentials_files = ["$HOME/.aws/credentials"]
 #profile                  = "prod"
}


# EKS Module
## Creating EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = "1.21"
  #cluster_iam_role_arn = var.cluster_iam_role_arn
  cluster_iam_role_name = var.cluster_iam_role_name
  vpc_id          = "vpc-XYZ" #module.vpc.vpc_id
  subnets         = ["subnet-XYZ" , "subnet-XYZ" ] #module.vpc.public_subnets
  #fargate_subnets = [module.vpc.private_subnets[2]]

  cluster_endpoint_private_access = "false"
  cluster_endpoint_public_access  = "true"
  #write_kubeconfig      = true
  #config_output_path    = "~/.kube/"
  #manage_aws_auth       = true
  #write_aws_auth_config = true

  #map_users = [
  #  {
  #    user_arn = "arn:aws:iam::XYZZZ:user/abc"
  #    username = "abc"
  #    group    = "system:masters"
  #  },
  #]
}

#IAM OIDC

resource "aws_eks_identity_provider_config" "eksoid" {
  cluster_name = "test-Cluster"

  oidc {
    client_id                     = "sts.amazonaws.com"
    identity_provider_config_name = "EKS-Config"
    issuer_url                    = aws_iam_openid_connect_provider.default.url #module.eks.cluster_oidc_issuer_url
  }
}

## Adding the Identity Provider Info

resource "aws_iam_openid_connect_provider" "default" {
  url = module.eks.cluster_oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [ "xxxxxxxxxx22da2b0ab7280" ]
}

## Creating IAM Role for Node Group (Only to Be Created for a Complete New Environment)

#resource "aws_iam_role" "example" {
#  name = "eks-node-group-example"

#  assume_role_policy = jsonencode({
#    Statement = [{
#      Action = "sts:AssumeRole"
#      Effect = "Allow"
#      Principal = {
#        Service = "ec2.amazonaws.com"
#      }
#    }]
#    Version = "2012-10-17"
#  })
#}

#resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#  role       = aws_iam_role.example.name
#}

#resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#  role       = aws_iam_role.example.name
#}

#resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#  role       = aws_iam_role.example.name
#}


## Creating Node Groups - Using RESOURCE 

#resource "aws_eks_node_group" "MainNode" {
#  cluster_name    = var.cluster_name
#  node_group_name = "MainNode-32Gb"
#  node_role_arn   = var.node_role_arn #["arn:aws:iam::xxxxxxxx:role/abc-role"]
#  subnet_ids      = ["subnet-xxxxxxx"]

#  scaling_config {
#    desired_size = 0
#    max_size     = 2
#    min_size     = 0
#  }

#  update_config {
#    max_unavailable = 1
#  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#  depends_on = [
#    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
#    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
#    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
#  ]
#}

## Creating Node Group - Using Module
## Main Node 32 GB
module "main-node" {
  source = "umotif-public/eks-node-group/aws"
  version = "~> 4.0.0"

  cluster_name = var.cluster_name
  disk_size = 50
  node_group_name_prefix = "MainNode-32Gb"
  node_role_arn = var.node_role_arn
  subnet_ids = ["subnet-xxxxxx" ]  ##["subnet-1","subnet-2","subnet-3"]

  desired_size = 0
  min_size     = 0
  max_size     = 3

  instance_types = ["t3.2xlarge"]
  capacity_type  = "ON_DEMAND"

  #ec2_ssh_key = "key"

  labels = {
    disktype = "main_node"
  }

  force_update_version = false

  tags = {
    Name = "MainNode-32Gb"
  }
  depends_on = [
    module.eks
  ]
}

## Model Calculation Node 

module "model-node" {
  source = "umotif-public/eks-node-group/aws"
  version = "~> 4.0.0"

  cluster_name = var.cluster_name
  disk_size = 30
  node_group_name_prefix = "Model"
  node_role_arn = var.node_role_arn
  subnet_ids = ["subnet-xxxxxxx" ]  ##["subnet-1","subnet-2","subnet-3"]

  desired_size = 0
  min_size     = 0
  max_size     = 10

  instance_types = ["t3.xlarge"]
  capacity_type  = "ON_DEMAND"

  #ec2_ssh_key = "key"

  labels = {
    superman = "primary"
  }
  
  force_update_version = false

  tags = {
    Name = "Model"
  }
  depends_on = [
    module.eks
  ]
}

## Cluster Autoscaler

module "cluster_autoscaler" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-cluster-autoscaler.git"

  enabled = true

  cluster_name                     = var.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  aws_region                       = "eu-central-1"
}

## Adding the Cluster's  Add-On

resource "aws_eks_addon" "vpc-cni" {
  addon_name   = "vpc-cni"
  cluster_name = var.cluster_name
  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "coredns" {
  addon_name   = "coredns"
  cluster_name = var.cluster_name
  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "aws-ebs-csi-driver" {
  addon_name   = "aws-ebs-csi-driver"
  cluster_name = var.cluster_name
  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "kube-proxy" {
  addon_name   = "kube-proxy"
  cluster_name = var.cluster_name
  depends_on = [
    module.eks
  ]
}
