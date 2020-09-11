#create vpc and resource vpc
resource "aws_vpc" "akaforcus"{
    cidr_block = "10.10.0.0/16"
    tags = {
        Name = "akaFORCUS"
        "Created By" = "${var.createdby}"
    }
}

#create internet gateway for intergration with ssh bastion
resource "aws_internet_gateway" "igwmain" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    tags = {
        Name = "akaforcus internet gateway"
        "Created By" = "${var.createdby}"
    }
}

#create subnet

#bastion subnet 10.10.9.0/24
resource "aws_subnet" "bastion" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    cidr_block = "10.10.9.0/24"
    tags = {
        Name = "bastion-subnet"
        "Created By" = "${var.createdby}"
    }
}

#webappi subnet 10.10.10.0/24
resource "aws_subnet" "webappizonea" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    cidr_block = "10.10.10.0/24"
    availability_zone = "${var.azonea}"

    tags = {
        Name = "webappi-subnet-zone-a"
        "Created By" = "${var.createdby}"
    }
}
#webappi subnet 10.10.11.0/24
resource "aws_subnet" "webappizoneb" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    cidr_block = "10.10.11.0/24"
    availability_zone = "${var.azoneb}"
    tags = {
        Name = "webappi-subnet-zone-b"
        "Created By" = "${var.createdby}"
    }
}

#databa subnet 10.10.12.0/24
resource "aws_subnet" "database" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    cidr_block = "10.10.12.0/24"
    tags = {
        Name = "database-subnet"
        "Created By" = "${var.createdby}"
    }
}
#cronjob subnet 10.10.13.0/24
resource "aws_subnet" "cronjob" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    cidr_block = "10.10.13.0/24"
    tags = {
        Name = "analytics-subnet"
        "Created By" = "${var.createdby}"
    }
}

#create route table
resource "aws_default_route_table" "akaforcus-route" {
  default_route_table_id = "${aws_vpc.akaforcus.default_route_table_id}" #applied this when create default route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igwmain.id}"
  }

  tags = {
    Name = "akaforcus-vpc-route"
    "Created By" = "${var.createdby}"
  }
}

# set main route table
resource "aws_main_route_table_association" "a" {
  vpc_id = "${aws_vpc.akaforcus.id}"
  route_table_id = "${aws_default_route_table.akaforcus-route.id}"
}

# Subnet Associations
resource "aws_route_table_association" "a" {
  route_table_id = "${aws_default_route_table.akaforcus-route.id}"
  subnet_id = "${aws_subnet.bastion.id}"
}

#edit default security group
resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.akaforcus.id}"
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

#create list security group
#security group for api instance 
resource "aws_security_group" "api_instance_sg"{
    vpc_id = "${aws_vpc.akaforcus.id}"
    name = "SSH to api instance"
    description = "Allow admin group users can access to instance and managemnet"

    #setup ingress
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.10.9.0/24"]
    }
    #setup exposo docker 
    ingress{
        from_port = "${var.docker-api-port-expose}"
        to_port = "${var.docker-api-port-expose}"
        protocol = "tcp"
        cidr_blocks = ["10.10.0.0/16"]
    }

    tags = {
        Name = "SSH admin group"
        "Created By" = "${var.createdby}"
    }
}

#security group for ssh bastion
resource "aws_security_group" "bastion_admin_sg" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    name = "Bastion Security Group FOR ADMIN"
    description = "Allow admin group users can access to VPC"

    #setup ingress
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["171.255.69.138/32"]
    }
    tags = {
        Name = "SSH admin group"
        "Created By" = "${var.createdby}"
    }
}

#security group for rds instance
resource "aws_security_group" "rds_access_sg" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    name = "Database Connection"
    description = "Allow internal VPC connection RDS port"

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.10.0.0/16"] #cidr of vpc
    }
    tags = {
        Name = "RDS group"
        "Created By" = "${var.createdby}"
    }
}

#security group for loadblancer
resource "aws_security_group" "apilb_sg" {
    vpc_id = "${aws_vpc.akaforcus.id}"
    name = "Exposes Internet Connection"
    description = "Allow Client can connection to port 443"

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] #cidr of vpc
    }
    tags = {
        Name = "API Internet Expose"
        "Created By" = "${var.createdby}"
    }
}

#create s3
resource "aws_s3_bucket" "staticweb"{
    bucket = "akaforcus-bucket-staticweb"
    acl = "private"  # just expose for cloudfront

    #set mode static bucket hosting
    website {
        index_document = "index.html"
        error_document = "error.html"
    }

    #setup CORS 
    cors_rule {
        allowed_headers = ["Authorization"]
        allowed_methods = ["GET", "HEAD", "POST", "DELETE"]
        allowed_origins = ["*"]
        max_age_seconds = 3000
    }
}

#create cloudfront and assosicate with s3 and public policy
# resource "aws_cloudfront_distribution" "frontweb"{
#     #setup origin
#     origin {
#         domain_name = "${aws_s3_bucket.staticweb.bucket_regional_domain_name}"
#     }
# }

#create ec2 instance bastion
resource "aws_instance" "bastion_host" {
    ami = "${var.aws-linux2}"
    instance_type = "${var.bastion-size}"
    key_name = "${var.bastionkey}"
    vpc_security_group_ids = ["${aws_security_group.bastion_admin_sg.id}"]
    subnet_id = "${aws_subnet.bastion.id}"
    tags = {
        Name = "Bastion Host"
        "Created By" = "${var.createdby}"
    }
}
#create public ip and attach to bastion
resource "aws_eip" "bastionserver"{
    instance =  "${aws_instance.bastion_host.id}"
    vpc = true
    tags = {
        Name = "EIP Bastion HOST"
        "Created By" = "${var.createdby}"
    }
}

#create ec2 instance api 
resource "aws_instance" "apiinstance-zonea" {
    ami = "${var.aws-linux2}"
    instance_type = "${var.api-size}"
    key_name = "${var.bastionkey}"
    vpc_security_group_ids = ["${aws_security_group.api_instance_sg.id}"]
    subnet_id = "${aws_subnet.webappizonea.id}"
    tags = {
        Name = "API Instance AZ-A"
        "Created By" = "${var.createdby}"
    }
}

resource "aws_instance" "apiinstance-zoneb" {
    ami = "${var.aws-linux2}"
    instance_type = "${var.api-size}"
    key_name = "${var.bastionkey}"
    vpc_security_group_ids = ["${aws_security_group.api_instance_sg.id}"]
    subnet_id = "${aws_subnet.webappizoneb.id}"
    tags = {
        Name = "API Instance AZ-B"
        "Created By" = "${var.createdby}"
    }
}

#create lb for api
resource "aws_lb" "apibackend_lb"{
    name = "apiendpoint-alb"
    load_balancer_type = "application"
    internal = false
    #setup security group
    security_groups = ["${aws_security_group.apilb_sg}"]
    subnets = ["${aws_subnet.webappizonea.id},${aws_subnet.webappizoneb.id}"]
}