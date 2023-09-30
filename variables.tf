variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24"]

}
variable "private_subnet_cidr" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "env_prefix" {
  type    = string
  default = "dev"
}
variable "my_ip" {}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}