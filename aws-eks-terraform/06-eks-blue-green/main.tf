module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0" # module version constraint

  name               = "${var.project}-${var.environment}"
  kubernetes_version = "1.33" # latest supported version (update if newer is supported)

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    metrics-server = {}
  }

  endpoint_public_access = false
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  create_node_security_group = false
  create_security_group      = false
  security_group_id          = local.eks_control_plane_sg_id
  node_security_group_id     = local.eks_node_sg_id

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    blue = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 2
      max_size     = 10
      desired_size = 2

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
      }
    }

    /* green = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]

      min_size     = 2
      max_size     = 10
      desired_size = 2

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
      }

      /* taints = {
        upgrade = {
          key    = "upgrade"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
     } 
    } */
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    }
  )
}
