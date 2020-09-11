topology

igw => vpc => bastion subnet |  private subnet 
- bastion subnet consist a small ec2 to ssh allow just your public ip



NOTED: you have to created KeyPair first
To using specify variable file
using this CMD
terraform apply -auto-approve -var-file="variablesfie.tf"