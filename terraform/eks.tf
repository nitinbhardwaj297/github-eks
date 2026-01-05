module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.k8s_cluster_name
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  authentication_mode = "API"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa         = true

  access_entries = {
    nitin = {
      principal_arn = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:user/${var.DEVELOPER_NAME}"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    github_actions = {
      principal_arn = aws_iam_role.github_actions.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    thor-nodegroup = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      subnet_ids     = module.vpc.private_subnets
    }
  }

  cluster_addons = {
    vpc-cni    = { most_recent = true }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
  }
}


