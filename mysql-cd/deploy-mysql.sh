#!/bin/bash

set -euo pipefail

NAMESPACE="roboshop"
SERVICE_ACCOUNT="roboshop-mysql-secret-reader-sa"
ROLE_NAME="MySQLEBSSecretReaderRole"
POLICY_NAME="AmazonEBSCSIDriverPolicy"

echo "🔹 Getting AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "Account ID: $ACCOUNT_ID"

echo "🔹 Getting OIDC provider for EKS cluster..."
OIDC_PROVIDER=$(aws eks describe-cluster \
  --name roboshop-dev \
  --region us-east-1 \
  --query "cluster.identity.oidc.issuer" \
  --output text | sed -e "s/^https:\/\///")
echo "OIDC Provider: $OIDC_PROVIDER"

echo "🔹 Creating IAM policy for EBS CSI if not exists..."
aws iam create-policy \
  --policy-name $POLICY_NAME \
  --policy-document file://ebs-csi-policy.json || echo "Policy already exists, skipping..."

echo "🔹 Creating IAM role for ServiceAccount..."
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$OIDC_PROVIDER:sub": "system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json || echo "Role already exists, skipping..."

aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME || echo "Policy already attached, skipping..."

echo "🔹 Creating Kubernetes ServiceAccount with IRSA..."
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

kubectl create serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

kubectl annotate serviceaccount \
  -n $NAMESPACE $SERVICE_ACCOUNT \
  eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME \
  --overwrite

echo "✅ Setup completed. Verify with:"
echo "kubectl describe sa $SERVICE_ACCOUNT -n $NAMESPACE"
