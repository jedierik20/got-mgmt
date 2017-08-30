  source = "/Users/ecummings/repos/got-service-mgmt/common/run/vpc/main.tf"

  name = "my-vpc"

  cidr = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = "false"

  azs      = ["us-west-2a", "us-west-2b", "us-west-2c"]

  tags {
    "Terraform" = "true"
    "Environment" = "perfstage1"
  }

