locals {
  name_prefix   = "armageddon-class7"
  db_prefix     = "lab-mysql"
  terraform_tag = "made in Terraform"
}

##########################################
### Locals for Network Resources
##########################################
##### Map resource defined in variables.tf and subnets defined in tfvars file
## subnets = {
#    public-a = {
#    cidr_block        = "10.10.0.0/24"
#    availability_zone = "us-east-1a"
#    type              = "public"
#  }


### Iterate through all subnets created by aws_subnet.that, and 
### collect the ids of each subnet only if its type is "public".
locals {
  public_subnet_ids = [
    for k, s in aws_subnet.dev :
    s.id if var.subnets[k].type == "public"
  ]
}

# Iterate through all subnets created by aws_subnet.that, and 
# collect the ids of each subnet only if its type is "public" & "private".
# Store in a new map where k is key and s is subnet object.
locals {
  public_subnets = {
    for k, s in aws_subnet.dev : k => s
    if var.subnets[k].type == "public"
  }
  private_subnets = {
    for k, s in aws_subnet.dev : k => s
    if var.subnets[k].type == "private"
  }
}

