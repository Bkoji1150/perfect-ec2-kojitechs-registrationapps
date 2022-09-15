
locals {
  name            = "kojitechs-${replace(basename(var.component_name), "-", "-")}"
}

# sg for database
resource "aws_security_group" "mysql_sg" {
  name        = "mysql_sg"
  description = "allow registration_app"
  vpc_id      = local.vpc_id

  ingress {
    description     = "allow registration_app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.registration_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql_sg"
  }
}

module "aurora" {
  source = "git::https://github.com/Bkoji1150/aws-rdscluster-kojitechs-tf.git?ref=v1.1.0"

  component_name = var.component_name
  name           = local.name
  engine         = "aurora-postgresql"
  engine_version = "11.15"
  instances = {
    1 = {
      instance_class      = "db.r5.2xlarge"
      publicly_accessible = false
    }
  }

  vpc_id                 = local.vpc_id
  create_db_subnet_group = true
  subnets                = local.pri_subnet
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]

  iam_database_authentication_enabled = true
  apply_immediately                   = true
  skip_final_snapshot                 = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  database_name                       = var.database_name
  master_username                     = var.master_username
}
