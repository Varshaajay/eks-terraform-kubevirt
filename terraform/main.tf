module "vpc" {
  source = "./vpc"

  project_name = "platform-dev"
  region       = "us-east-1"
}

module "eks" {
  source = "./eks"

  cluster_name = "platform-dev"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
