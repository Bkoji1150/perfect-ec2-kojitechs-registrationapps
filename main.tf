
locals {
  vpc_id           = data.aws_vpc.vpc.id
  pub_subnet       = [for i in data.aws_subnet.public_sub : i.id]
  pri_subnet       = [for i in data.aws_subnet.priv_sub : i.id]
  instance_profile = aws_iam_instance_profile.instance_profile.name
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
# https://domain_name/
#### App2(frontend)
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
resource "aws_instance" "registration_app" {
  depends_on = [module.aurora]
  count      = length(var.name)

  ami                    = data.aws_ami.ami.id
  instance_type          = "t2.micro"
  subnet_id              = element(local.pri_subnet, count.index)
  iam_instance_profile   = local.instance_profile
  vpc_security_group_ids = [aws_security_group.registration_app.id]
  user_data = templatefile("${path.root}/template/registration_app.tpl",
    {
      endpoint    = "" # database_endpoint
      port        = "" # database port 
      db_name     = "" # database name
      db_user     = "" # database user
      db_password = "" # database_password ? 
    }
  )
  tags = {
    Name = var.name[count.index]
  }
}


### mysql Aurora database (15m) 