### Description ###
This is a terraform project to create a VPC with 4 subnets, 2 public and 2 private, and EC2 in one publicsubnet and start nginx server.

# To run this project
You need to have terraform installed on your machine.
You need to have an AWS account and create an IAM user with programmatic access and necessary permissions.
### initialize

    terraform init

### preview terraform actions

    terraform plan

### apply configuration with variables

    terraform apply -var-file terraform-dev.tfvars

### destroy a single resource

    terraform destroy -target aws_vpc.myapp-vpc

### destroy everything fromtf files

    terraform destroy

### show resources and components from current state

    terraform state list

### show current state of a specific resource/data

    terraform state show aws_vpc.myapp-vpc    

### set avail_zone as custom tf environment variable - before apply

    export TF_VAR_avail_zone="eu-west-3a"