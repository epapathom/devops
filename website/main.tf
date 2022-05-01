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
    key    = "website/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_security_group" "website_lb_sg" {
  name        = "website-lb-sg"
  description = "The website Load Balancer security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "website_sg" {
  name        = "website-sg"
  description = "The website EC2 security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.website_lb_sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.website_lb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_configuration" "website_launch_configuration" {
  name_prefix     = "website-"
  instance_type   = "t2.small"
  key_name        = "epapathom-dev"
  image_id        = var.website_ami
  security_groups = [aws_security_group.website_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "website_autoscaling_group" {
  name                 = aws_launch_configuration.website_launch_configuration.name
  launch_configuration = aws_launch_configuration.website_launch_configuration.name
  target_group_arns    = [aws_lb_target_group.website_tg.arn]
  vpc_zone_identifier  = [var.public_subnet_a_id, var.public_subnet_b_id, var.public_subnet_c_id]
  min_elb_capacity     = 1
  desired_capacity     = 1
  min_size             = 1
  max_size             = 2

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "website"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "website_lb" {
  name               = "website-lb"
  load_balancer_type = "application"
  subnets            = [var.public_subnet_a_id, var.public_subnet_b_id, var.public_subnet_c_id]
  security_groups    = [aws_security_group.website_lb_sg.id]
}

resource "aws_lb_target_group" "website_tg" {
  name                 = "website-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 0
}

resource "aws_lb_listener" "website_lb_http_listener" {
  load_balancer_arn = aws_lb.website_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "website_lb_https_listener" {
  load_balancer_arn = aws_lb.website_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_id

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.website_tg.arn
  }
}
