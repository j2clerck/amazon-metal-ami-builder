# © 2018 Amazon Web Services, Inc. or its affiliates. All Rights Reserved. 
# This AWS Content is provided subject to the terms of the AWS Customer Agreement 
# available at http://aws.amazon.com/agreement or other written agreement between 
# Customer and Amazon Web Services, Inc.

module "vpc" {
  source   = "modules/vpc"
  vpc_name = "DEMO"
  vpc_cidr = "192.168.0.0/24"
}

terraform {
  backend = "s3"
  config {
    bucket = "clerckj"
    key    = "terraform-states/amazon-metal.tfstate"
    region = "eu-west-1"
  }
}

data "aws_ami" "amzn-linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"]

}
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}