## Create OIDC

To enable IAM Roles for Service Accounts (IRSA) in EKS, you need the cluster's OIDC provider ID.  
Follow the steps below to extract it:

```bash
# Set your EKS cluster name
export cluster_name=roboshop-dev

# Get OIDC ID directly and strip quotes
oidc_id=$(aws eks describe-cluster \
  --name $cluster_name \
  --query "cluster.identity.oidc.issuer" \
  --output text | awk -F'/' '{print $5}' | tr -d '"')

# Verify the value
echo $oidc_id