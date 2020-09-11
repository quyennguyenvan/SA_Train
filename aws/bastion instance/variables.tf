# declarative

variable "aws-linux2" {
    type = "string"
    default = "ami-0099823645f06b6a1"
}

#set key pair name
variable "bastionkey" { 
    type = "string"
    default = "bastion-key"
}