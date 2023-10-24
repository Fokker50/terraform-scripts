module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.1"

  cluster_name    = "my-eks"
  cluster_version = "1.27"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 20
  }

  eks_managed_node_groups = {
    green = {
      desired_size = 1
      min_size     = 1
      max_size     = 2

      labels = {
        role = "green"
      }

      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }

    blue = {
      desired_size = 1
      min_size     = 1
      max_size     = 10

      labels = {
        role = "blue"
      }

      taints = [{
        key    = "market"
        value  = "spot"
        effect = "NO_SCHEDULE"
      }]

      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"
    }
  }

  

  tags = {
    Environment = "staging"
  }
}


