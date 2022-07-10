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
    key    = "ecs/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_security_group" "ecs-project-lb-sg" {
  name        = "ecs-project-lb-sg"
  description = "Allow all traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow all traffic"
    from_port        = 80
    to_port          = 80
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

resource "aws_lb" "ecs-project-lb" {
  name               = "ecs-project-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs-project-lb-sg.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "ecs-project-tg" {
  name        = "ecs-project-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "ecs-project-lb-listener" {
  load_balancer_arn = aws_lb.ecs-project-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-project-tg.arn
  }
}

resource "aws_ecs_cluster" "ecs-project-cluster" {
  name = "ecs-project-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecs-project-task-role" {
  name = "ecs-project-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "ecs-project-task-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_ecs_task_definition" "ecs-project-task-definition" {
  family                   = "ecs-project-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs-project-task-role.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-project-container"
      image     = var.ecr_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    }
  ])
}

resource "aws_security_group" "ecs-project-service-sg" {
  name        = "ecs-project-service-sg"
  description = "Allow all traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow all traffic"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs-project-lb-sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_service" "ecs-project-service" {
  name            = "ecs-project-service"
  cluster         = aws_ecs_cluster.ecs-project-cluster.id
  task_definition = aws_ecs_task_definition.ecs-project-task-definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.ecs-project-service-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs-project-tg.arn
    container_name   = "ecs-project-container"
    container_port   = 5000
  }
}
