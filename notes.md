Create OIDC:
'''
export cluster_name=roboshop-dev
  
  # Get OIDC ID directly and strip quotes
oidc_id=$(aws eks describe-cluster \
  --name $cluster_name \
  --query "cluster.identity.oidc.issuer" \
  --output text | awk -F'/' '{print $5}' | tr -d '"')
  '''