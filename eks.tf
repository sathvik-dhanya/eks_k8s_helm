provider "aws" {
  version = "~> 2.7.0"
  region  = "us-east-1"
}

# create EKS cluster
module "my_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "4.0.2"

  cluster_name = "my_cluster"
  subnets      = [""] # add subnets IDS
  vpc_id       = "" # add vpc ID

  worker_groups = [
    {
      name                 = "cluster-workers"
      instance_type        = "t3.small"
      root_volume_type     = "gp2"
      root_volume_size     = "50"
      public_ip            = false
      asg_desired_capacity = "3"
      asg_max_size         = "3"
    },
  ]

  worker_group_count    = "1"
  # these two lines can be set to true if you need a local copy of kubeconfig and the aws_auth_config
  write_aws_auth_config = "false"
  write_kubeconfig      = "false"

  tags = {
    env        = "test"
    stack_name = "test"
  }
}
