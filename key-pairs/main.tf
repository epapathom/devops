terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "epapathom-terraform-state"
    key    = "ec2-key/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "epapathom-dev"
  public_key = tls_private_key.private_key.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.private_key.private_key_pem}' > ../../epapathom-dev.pem"
  }
}
