## Configure OIDC for EKS

EKS needs an **OIDC provider** to enable IAM Roles for Service Accounts (IRSA).  
Follow these steps:

---

### 1. Set your cluster name
```bash
export cluster_name=roboshop-dev
2. Get the OIDC ID
bash
Copy code
oidc_id=$(aws eks describe-cluster \
  --name $cluster_name \
  --query "cluster.identity.oidc.issuer" \
  --output text | awk -F'/' '{print $5}' | tr -d '"')

echo $oidc_id
Sample output:

Copy code
522A91C658724C6DF802119433C93697
3. Check if OIDC is already configured
bash
Copy code
aws iam list-open-id-connect-providers | grep $oidc_id || echo "OIDC provider not found"
If you see an ARN → OIDC exists

If not → go to step 4

4. Create OIDC provider (only if missing)
bash
Copy code
eksctl utils associate-iam-oidc-provider \
  --cluster $cluster_name \
  --approve
5. Verify again
bash
Copy code
aws iam list-open-id-connect-providers | grep $oidc_id
Sample output:

ruby
Copy code
arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/522A91C658724C6DF802119433C93697
Why is this needed?
OIDC is required for EKS add-ons that need IAM access, such as:

ALB Ingress Controller

EBS CSI Driver

ExternalDNS

Other controllers that assume IAM roles

yaml
Copy code
