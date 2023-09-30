provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}
# Public Subnets
resource "aws_subnet" "public_subnet-1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr[0]
  availability_zone = var.azs[0]
  tags = {
    Name = "${var.env_prefix}-public_subnet-1"
  }
}

resource "aws_subnet" "public_subnet-2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr[1]
  availability_zone = var.azs[1]
  tags = {
    Name = "${var.env_prefix}-public_subnet-2"
  }
}
# Private Subnets
resource "aws_subnet" "private_subnet-1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidr[0]
  availability_zone = var.azs[0]
  tags = {
    Name = "${var.env_prefix}-private_subnet-1"
  }
}

resource "aws_subnet" "private_subnet-2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidr[1]
  availability_zone = var.azs[1]
  tags = {
    Name = "${var.env_prefix}-private_subnet-2"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw"
  }
}
# Route Tables
resource "aws_default_route_table" "my_public_route_table" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "${var.env_prefix}-public_route_table"
  }
}

resource "aws_route_table_association" "public_route_assoc-1" {
  subnet_id      = aws_subnet.public_subnet-1.id
  route_table_id = aws_vpc.my_vpc.default_route_table_id
}

resource "aws_route_table_association" "public_route_assoc-2" {
  subnet_id      = aws_subnet.public_subnet-2.id
  route_table_id = aws_vpc.my_vpc.default_route_table_id
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.env_prefix}-private_route_table"
  }
}

resource "aws_route_table_association" "private_route_assoc-1" {
  subnet_id      = aws_subnet.private_subnet-1.id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_route_table_association" "private_route_assoc-2" {
  subnet_id      = aws_subnet.private_subnet-2.id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.public_subnet-1.id
  tags = {
    Name = "${var.env_prefix}-nat_gateway"
  }
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.env_prefix}-my_eip"
  }
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.my_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}

resource "aws_default_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-def-my_SG"
  }
}

data "aws_ami" "latest_aws_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "ena-support"
    values = ["true"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
resource "aws_instance" "my_instance" {
  ami                         = data.aws_ami.latest_aws_ami.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key-tf.key_name
  vpc_security_group_ids      = [aws_default_security_group.my_security_group.id]
  subnet_id                   = aws_subnet.public_subnet-1.id
  availability_zone           = var.azs[0]
  associate_public_ip_address = true
  user_data                   = file("entry-script.sh")
  tags = {
    Name = "${var.env_prefix}-my_instance"
  }

}

resource "aws_key_pair" "ssh_key-tf" {
  key_name   = "my_server_key2"
  public_key = file(var.public_key_path)


}


output "aws_ami_id" {
  value = data.aws_ami.latest_aws_ami.id
}

output "aws_instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}



