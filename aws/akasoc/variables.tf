# declarative

variable "createdby"{
    default = "name_of_incharge_project_deployment_infra"
}

variable "azonea"{
    default = "ap-southeast-2a"
}
variable "azoneb" {
    default = "ap-southeast-2b"
}

variable "aws-linux2" {
    default = "ami-0099823645f06b6a1"
}

variable "bastion-size"{
    default = "t2.small"
}

variable "api-size" {
    default = "t2.medium"
}

#set key pair name
variable "bastionkey" { 
    default = "bastion-key"
}

variable "docker-api-port-expose" {
    default = 8083
}