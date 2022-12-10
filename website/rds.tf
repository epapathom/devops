resource "aws_security_group" "website_rds_sg" {
  name        = "website-rds-sg"
  description = "The wesbite RDS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.website_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_db_subnet_group" "website_rds_subnet_group" {
  name        = "website-rds-subnet-group"
  description = "The website RDS subnet group"
  subnet_ids  = [var.private_subnet_a_id, var.private_subnet_b_id, var.private_subnet_c_id]
}

resource "aws_db_instance" "website_rds" {
  allocated_storage         = 10
  identifier                = "website"
  db_name                   = "website"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t4g.micro"
  username                  = var.rds_username
  password                  = var.rds_password
  deletion_protection       = true
  final_snapshot_identifier = "website-final-snapshot"
  vpc_security_group_ids    = [aws_security_group.website_rds_sg.id]
  db_subnet_group_name      = aws_db_subnet_group.website_rds_subnet_group.name
}

output "rds_hostname" {
  value = aws_db_instance.website_rds.address
}
