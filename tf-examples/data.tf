data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  tags = {
    VpcAppTag = "PA-VPC"
  }
}


data "aws_subnet_ids" "primary" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    K8S-CNI = "Primary"
  }
}

data "aws_subnet_ids" "secondary" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    K8S-CNI = "Secondary"
  }
}
