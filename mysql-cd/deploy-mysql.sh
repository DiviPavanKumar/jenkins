#!/bin/bash
set -euo pipefail

# Variables
NAMESPACE="roboshop"
SERVICE_ACCOUNT="roboshop-mysql-secret-reader"
ROLE_NAME="RoboshopMySQLSecretReaderRole"
POLICY_NAME="RoboshopMySQLSecretReader"
REGION="us-east-1"
CLUSTER_NAME="roboshop-dev"

echo "🔹 Fetching AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "Account ID: $ACCOUNT_ID"

echo "🔹 Fetching OIDC provider for EKS cluster..."
OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
echo "OIDC Provider: $OIDC_PROVIDER"

echo "🔹 Creating mysql-secret-policy.json..."
cat > mysql-secret-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:${REGION}:${ACCOUNT_ID}:secret:${NAMESPACE}/mysql/password-*"
    }
  ]
}
EOF

echo "🔹 Creating IAM Policy (if not exists)..."
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
if [ -z "$POLICY_ARN" ]; then
    POLICY_ARN=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document file://mysql-secret-policy.json --query 'Policy.Arn' --output text)
    echo "Policy created: $POLICY_ARN"
else
    echo "Policy already exists: $POLICY_ARN"
fi

echo "🔹 Creating IAM Role for ServiceAccount (if not exists)..."
if ! aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
    cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}"
        }
      }
    }
  ]
}
EOF
    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
    echo "Role created: $ROLE_NAME"
else
    echo "Role already exists: $ROLE_NAME"
fi

echo "🔹 Attaching policy to IAM Role..."
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN || echo "Policy already attached"

echo "🔹 Creating and annotating Kubernetes ServiceAccount..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl annotate serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE eks.amazonaws.com/role-arn=arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} --overwrite

echo "✅ MySQL ServiceAccount with IRSA setup complete!"
echo "Verify with: kubectl describe sa $SERVICE_ACCOUNT -n $NAMESPACE"
