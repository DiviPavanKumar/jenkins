#!/bin/bash
set -e

# -----------------------------
# Variables
# -----------------------------
CLUSTER_NAME="roboshop-dev"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
NAMESPACE="kube-system"
SERVICE_ACCOUNT="ebs-csi-controller-sa"
IAM_ROLE="AmazonEKS_EBS_CSI_DriverRole"
TRUST_POLICY_FILE="trust-policy.json"
STORAGE_CLASS_NAME="roboshop-ebs-sc"

# -----------------------------
# Step 1: Get OIDC ID
# -----------------------------
OIDC_ID=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --query "cluster.identity.oidc.issuer" \
  --output text | awk -F'/' '{print $5}' | tr -d '"')

echo "OIDC ID: $OIDC_ID"

# -----------------------------
# Step 2: Create IAM Role with Trust Policy
# -----------------------------
cat > $TRUST_POLICY_FILE <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${OIDC_ID}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}"
        }
      }
    }
  ]
}
EOF

# Create IAM role if it doesn't exist
if ! aws iam get-role --role-name $IAM_ROLE &>/dev/null; then
    aws iam create-role \
        --role-name $IAM_ROLE \
        --assume-role-policy-document file://$TRUST_POLICY_FILE
fi

# Attach AWS managed policy
aws iam attach-role-policy \
  --role-name $IAM_ROLE \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

# -----------------------------
# Step 3: Install EBS CSI Driver via Helm
# -----------------------------
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm upgrade --install aws-ebs-csi-driver \
  --namespace $NAMESPACE \
  aws-ebs-csi-driver/aws-ebs-csi-driver

# -----------------------------
# Step 4: Annotate Service Account
# -----------------------------
kubectl annotate serviceaccount $SERVICE_ACCOUNT \
  -n $NAMESPACE \
  eks.amazonaws.com/role-arn=arn:aws:iam::${ACCOUNT_ID}:role/${IAM_ROLE} --overwrite

# -----------------------------
# Step 5: Restart CSI driver pods to pick up IAM Role
# -----------------------------
kubectl delete pods -n $NAMESPACE -l app.kubernetes.io/name=aws-ebs-csi-driver

# -----------------------------
# Step 6: Verification
# -----------------------------
echo "Checking service account annotation..."
kubectl get serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE -o yaml

echo "Checking CSI driver pods..."
kubectl get pods -n $NAMESPACE | grep ebs-csi

echo "✅ EBS CSI Driver with IRSA setup is complete."
