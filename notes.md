###1. AWS CLI Configuration

Set up AWS credentials:

aws configure
AWS Access Key ID [None]: <your-access-key>
AWS Secret Access Key [None]: <your-secret-key>
Default region name [None]: us-east-1
Default output format [None]:

###2. Install kubectl

Download, install, and verify kubectl:

# Download kubectl binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl
mkdir -p ~/.local/bin
mv kubectl ~/.local/bin/kubectl

# Verify installation
kubectl version --client

###3. Install eksctl

Download and install eksctl:

ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

# Download latest eksctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# Extract and install
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

###4. Connect kubectl to EKS cluster

Update kubeconfig:

aws eks update-kubeconfig --region us-east-1 --name roboshop-dev

# Verify access
kubectl get namespaces

###5. Get OIDC ID for EKS cluster

Retrieve OIDC provider ID (required for IAM roles for service accounts):

export cluster_name=roboshop-dev
oidc_id=$(aws eks describe-cluster \
  --name $cluster_name \
  --query "cluster.identity.oidc.issuer" \
  --output text | awk -F'/' '{print $5}' | tr -d '"')
echo $oidc_id

# Verify OIDC provider exists
aws iam list-open-id-connect-providers | grep $oidc_id || echo "OIDC provider not found"

###6. Install Helm (if not installed)
# Add EBS CSI driver repo
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

# Install the driver
helm upgrade --install aws-ebs-csi-driver \
    --namespace kube-system \
    aws-ebs-csi-driver/aws-ebs-csi-driver

###7. Create IAM Role for EBS CSI Driver

Create trust policy file (trust.json) for IRSA:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account-id>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/<oidc-id>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/<oidc-id>:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}


Create the role and attach policy:

# Create IAM role
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://trust.json

# Attach EBS CSI policy
aws iam attach-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

# Verify attached policy
aws iam list-attached-role-policies --role-name AmazonEKS_EBS_CSI_DriverRole

###8. Create IAM Service Account

Link the IAM role to Kubernetes service account using eksctl:

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster roboshop-dev \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts \
  --region us-east-1


Annotate service account with IAM role ARN:

kubectl annotate sa ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::<account-id>:role/AmazonEKS_EBS_CSI_DriverRole --overwrite


Verify the service account:

kubectl describe sa ebs-csi-controller-sa -n kube-system

###9. Verify StorageClass and PVC

Check available storage classes:

kubectl get sc


Check PVC status:

kubectl get pvc -n roboshop
kubectl describe pvc <pvc-name> -n roboshop


✅ At this point, the EBS CSI driver is correctly installed and IAM role is linked, allowing PV creation in the cluster.