
data "terraform_remote_state" "operational_environment" {
  backend = "s3"

  config = {
    region = "us-east-1"
    bucket = "operational.vpc.tf.kojitechs"
    key    = format("env:/%s/path/env", lower(terraform.workspace))
  }
}

locals {
  operational_state    = data.terraform_remote_state.operational_environment.outputs
  vpc_id               = local.operational_state.vpc_id
  pub_subnet        = local.operational_state.public_subnets
  pri_subnet      = local.operational_state.private_subnets
  private_sunbet_cidrs = local.operational_state.private_subnets_cidrs
  database_subnet      = local.operational_state.database_subnets
#   vpc_id           = data.aws_vpc.vpc.id
#   pub_subnet       = [for i in data.aws_subnet.public_sub : i.id]
#   pri_subnet       = [for i in data.aws_subnet.priv_sub : i.id]
  instance_profile = aws_iam_instance_profile.instance_profile.name
  mysql            = data.aws_secretsmanager_secret_version.rds_secret_target
  instances = {
    "app1" = {
      instance_type = "t2.xlarge"
      subnet_id     = local.pri_subnet[0]
      user_data     = file("${path.module}/template/frontend_app1.sh")
    }
    "app2" = {
      instance_type = "t2.xlarge"
      subnet_id     = local.pri_subnet[1]
      user_data     = file("${path.module}/template/frontend_app2.sh")
    }
  }
}

data "aws_secretsmanager_secret_version" "rds_secret_target" {

  depends_on = [module.aurora]
  secret_id  = module.aurora.secrets_version
}
    


resource "aws_instance" "frond_end" {
  for_each = {
    for id, instances in local.instances : id => instances
    if(var.environment != null)
  }
  ami                    = data.aws_ami.ami.id
  instance_type          = lookup(each.value, "instance_type")
  subnet_id              = lookup(each.value, "subnet_id")
  vpc_security_group_ids = [aws_security_group.front_app_sg.id]
  user_data              = lookup(each.value, "user_data")
  iam_instance_profile   = local.instance_profile

  tags = {
    Name = each.key
  }
}

resource "aws_instance" "registration_app" {
  depends_on = [module.aurora]
  count      = length(var.name)

  ami                    = data.aws_ami.ami.id
  instance_type          = "t2.xlarge"
  subnet_id              = element(local.pri_subnet, count.index)
  iam_instance_profile   = local.instance_profile
  vpc_security_group_ids = [aws_security_group.registration_app.id]
  user_data = templatefile("${path.root}/template/registration_app.tmpl",
    {
      endpoint    = jsondecode(local.mysql.secret_string)["endpoint"]
      port        = jsondecode(local.mysql.secret_string)["port"]
      db_name     = jsondecode(local.mysql.secret_string)["dbname"]
      db_user     = jsondecode(local.mysql.secret_string)["username"]
      db_password = jsondecode(local.mysql.secret_string)["password"]
    }
  )
  tags = {
    Name = var.name[count.index]
  }
}
