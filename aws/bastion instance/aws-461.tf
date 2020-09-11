/*
  topology

  igw => vpc => bastion subnet |  private subnet 
  - bastion subnet consist a small ec2 to ssh allow just your public ip
*/


# create a vpc
resource "aws_vpc" "devops" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "devops"
    "Created By" = "QuyenNV9 - ter"
    "Auto Created" = "True"
    "Tools" = "Ter"
  }
}


#create igw gateway
resource "aws_internet_gateway" "igwmain" {
  vpc_id = "${aws_vpc.devops.id}"
  tags = { 
    Name = "igw-devops-vpc"
    "Created By" = "QuyenNV9 - ter"
  }
}

resource "aws_subnet" "bastion" {
  vpc_id = "${aws_vpc.devops.id}"
  cidr_block = "10.10.10.0/24"
  tags = {
    Name = "Bastion Subnet"
    "Created By" = "QuyenNV9 - ter"
  }
}
resource "aws_subnet" "apiappsb"{
  vpc_id = "${aws_vpc.devops.id}"
  cidr_block = "10.10.11.0/24"
  tags = {
    Name = "App API Subnet"
    "Created By" = "QuyenNV9 - ter"
  }
}

#create route table
resource "aws_default_route_table" "devops-route" {
  #vpc_id = "${aws_vpc.devops.id}" #applied this when create new route
  default_route_table_id = "${aws_vpc.devops.default_route_table_id}" #applied this when create default route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igwmain.id}"
  }

  tags = {
    Name = "devops-vpc-route"
    "Created By" = "QuyenNV9 - ter"
  }
}

# set main route table
resource "aws_main_route_table_association" "a" {
  vpc_id = "${aws_vpc.devops.id}"
  route_table_id = "${aws_default_route_table.devops-route.id}"
}

# Subnet Associations
resource "aws_route_table_association" "a" {
  route_table_id = "${aws_default_route_table.devops-route.id}"
  subnet_id = "${aws_subnet.bastion.id}"
}
#edit default security group
resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.devops.id}"
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1  #all protocol
    cidr_blocks = ["10.10.0.0/16"] #restrict security default
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = -1  #all protocol
    cidr_blocks = ["0.0.0.0/0"] 
  }
  tags = {
    Name = "Default VPC Security Group"
    Restrict = "Yes"
  }
}

#create security group
resource "aws_security_group" "bastion_admin_sg" {
  vpc_id = "${aws_vpc.devops.id}"
  name = "bastion admin for management"
  description = "Allow user admin can access to this instance"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["171.253.98.205/32"]
  }
  tags = {
    Name = "bastion admin sg"
    "Created By" = "QuyenNV9 - ter"
  }
}
#create keypair file
# resource "aws_key_pair" "bastion" {
#   key_name = "bastion-key"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 quyennv9@fsoft.com"
#   tags = {
#     Name = "devops-bastion-key"
#     "Created By" = "QuyenNV9 - ter"
#   }
# }
#create ec2
resource "aws_instance" "bastion_instance" {
  ami = "${var.aws-linux2}"
  instance_type = "t2.small"
  key_name = "${var.bastionkey}"
  vpc_security_group_ids = ["${aws_security_group.bastion_admin_sg.id}"]
  subnet_id = "${aws_subnet.bastion.id}"
  tags = {
    Name = "Bastion HOST"
    "Created By" ="QuyenNV9 - ter"
  }
}

#create public ip and attach to ec2
resource "aws_eip" "bastionserver"{
 instance =  "${aws_instance.bastion_instance.id}"
 vpc = true
 tags = {
   Name = "EIP Bastion HOST"
   "Created By" = "QuyenNV9 - ter"
 }
}


