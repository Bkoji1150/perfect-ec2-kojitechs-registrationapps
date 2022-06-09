
locals {
  vpc_id           = data.aws_vpc.vpc.id
  pub_subnet       = [for i in data.aws_subnet.public_sub : i.id]
  pri_subnet       = [for i in data.aws_subnet.priv_sub : i.id]
  instance_profile = aws_iam_instance_profile.instance_profile.name
  mysql = data.aws_secretsmanager_secret_version.rds_secret_target
}

data "aws_secretsmanager_secret_version" "rds_secret_target" {

  depends_on = [module.aurora]
  secret_id  = module.aurora.secrets_version
}

### APP1(frontend)
# apache (index.html) # . app1, app2 (install using userdata)
resource "aws_instance" "front_endapp1" {
  ami                    = data.aws_ami.ami.id
  instance_type          = "t2.micro"
  subnet_id              = local.pri_subnet[0]
  vpc_security_group_ids = [aws_security_group.front_app_sg.id]
  user_data              = file("${path.module}/template/frontend_app1.sh")
  iam_instance_profile   = local.instance_profile

  tags = {
    Name = "front_endapp1"
  }
}

# App2(frontend)
resource "aws_instance" "front_endapp2" {
  ami                    = data.aws_ami.ami.id
  instance_type          = "t2.micro"
  subnet_id              = local.pri_subnet[1]
  vpc_security_group_ids = [aws_security_group.front_app_sg.id]
  user_data              = file("${path.module}/template/frontend_app2.sh")
  iam_instance_profile   = local.instance_profile

  tags = {
    Name = "front_endapp2"
  }
}

#### registration app (2)
# we have two instances her
# aws_instance.registration_app[0].id 
# 
resource "aws_instance" "registration_app" {
  depends_on = [module.aurora]
  count      = length(var.name)

  ami                    = data.aws_ami.ami.id
  instance_type          = "t2.xlarge"
  subnet_id              = element(local.pri_subnet, count.index)
  iam_instance_profile   = local.instance_profile
  vpc_security_group_ids = [aws_security_group.registration_app.id]
  key_name = "testkeypair"
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