### Description ###
This project is a representation of modularized terraform code for AWS infrastructure.
It creates a VPC with 2 public and 2 private subnets in 2 availability zones and EKS cluster with 2 worker nodes.
### Prerequisites ###
- Terraform ~> 1.5.7
- AWS CLI ~> 2.13.21
- kubectl ~> 1.28.2

### To create VPC and EKS cluster ###
1. First of all, we need to define AWS provider in    0-aws-provider.tf file. Its a best practice to define provider in separate file and define version constraint.
We will need terraform version itself and kubectl and helm providers.

2. Authentication to AWS there are 2 options:
- Using AWS CLI profile (aws configure --profile <profile_name>)
- If you run terraform from EC2 instance, you can use IAM role attached to EC2 instance.

3. Create VPC and EKS cluster. We will use terraform modules for that. Modules are located in modules directory.

terraform init
terraform apply
aws eks update-kubeconfig --name my-eks --region us-east-1
kubectl get nodes

4. Add IAM user & role to EKS cluster. Grant access to the IAM roe just once using aws-auth configmap located in kube-system namespace. We will use kubectl provider for that. We wiil create an IAM role with the necessary permissions and allow the IAM user to assume that role.
- Create an allow-eks-access IAM policy with eks:DescribeCluster action.
- Create IAM role that we will use to access EKS cluster. We will call it eks-admin because it will be binded to K8 system:masters RBAC group with full access to the k8 API.
- Attach IAM policy to the role and define trusted role ARN. By specifying the root potentially every user in the account can assume this role. We can specify the IAM user ARN instead.
- Create test IAM user and attach eks-admin role to it.
- Finally, we need to create IAM group with previously created policy and put test user into it.
terraform init
terraform apply

5. Generate new credentials and create a local AWS profile.
aws configure --profile user1
 - Veruify tha we can acces AWS using new profile.
aws sts get-caller-identity --profile user1
- To let user1 assume eks-admin IAm role we need to create a new profile in ~/.aws/config file.
vim ~/.aws/config
[profile user1]
role_arn = arn:aws:iam::123456789012:role/eks-admin #replace with your role ARN
source_profile = user1
- Test that user1 can assume eks-admin role.
aws sts get-caller-identity --profile user1

6. Now we can update kubekonfig to use eks-admin IAM role.
aws eks update-kubeconfig --name my-eks --region us-east-1 --profile eks-admin
Now we can use kubectl to access EKS cluster.
kubectl auth can-i '*' '*'

7. Add eks-admin role to the EKS cluster, we will update aws-auth configmap.

8. Authorize terraform to access Kubernetes API and modify aws-auth configmap. To do that, you need to define terraform kubernetes provider. To authenticate with the cluster, you can use either use token which has an expiration time or an exec block to retrieve this token on each terraform run.

terraform init
terraform apply
let's check if we access cluster using eks-admin role.
kubectl auth can-i '*' '*'
9. Deploy cluster autoscaler. We will use helm provider for that.
- Create a service account for cluster autoscaler.
- Deploy cluster autoscaler using kubectl provider.
terraform init
terraform apply
kubectl get pods -n kube-system

10. To test autoscler deploy nginx deployment with 2 replicas.

kubectl logs -f -n kube-system -l app=cas-autoscaler

11. Apply Kubernetes deployment 
kubectl apply -f k8s/nginx.yaml

12. Deploy AWS load balancer controller. We will use helm provider for that.
- Define helm provider.
- Create a service account for AWS load balancer controller.
- Deploy AWS load balancer controller in kube-system namespace.
- Then helm release. We need to specify EKS cluster name , k8 service account name and provide annotation to allow this service account to assume AWS IAM role.
13. Add tags for load balanncer controller in the VPC module.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
14. Allow access from EKS control plane to the webhooks port of the AWS load balancer controller. 
 
terraform init
terraform apply

kubectl logs -f -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller

15. To test, let's create an echo server deployment with ingress.

kubectl apply -f k8s/echo-server.yaml

16. To make ingress work, we need to create a DNS record for the load balancer. CNAME record for the load balancer DNS name.
kubectl get ingress
curl http://echo.example.com

