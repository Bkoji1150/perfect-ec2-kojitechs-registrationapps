
variable "vpc_id" {
  default = ""
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "component_name" {
  default = "kojitechs"
}

variable "name" {
  type    = list(any)
  default = ["registration_app1", "registration_app2"]
}

variable "dns_name" {
  type = string
}

variable "subject_alternative_names" {
  type    = list(any)
}


variable "environment" {
  description = "Environment this template would be deployed to"
  type        = map(string)
  default     = {}
}
