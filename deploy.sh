#!/usr/bin/env bash

echo "*** Begin Deployment ***"

echo "*** Launching Environment ***"

#cd terraform
#terraform init
#terraform plan -out out.terraform
#terraform apply out.terraform

echo "*** Build Docker Image ***"
#cd ..
#docker build . -t 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo:latest

echo "*** Login To ECR ***"
#aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo

echo "*** Push Docker Image To ECR ***"
#docker push 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo:latest

echo "*** Get EKS Cluster Name ***"
CLUSTERNAME=$(eksctl get cluster --output=json | jq -r '.[].Name')
echo ${CLUSTERNAME}

echo "*** Update Kube-Config For EKS ***"
#aws eks update-kubeconfig --region us-east-1 --name=${CLUSTERNAME}

echo "*** Create Kubernetes Namespace"
#kubectl create namespace liatrio-time-exercise

echo "*** Deploy Container To EKS Cluster ***"
#kubectl apply -f deployment.yaml

echo "*** Deploy Service To EKS Cluster ***"
#kubectl apply -f service.yaml

echo "*** Download IAM Policy For Load Balancer Controller ***"
curl -o iam_policy_us-gov.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy_us-gov.json

echo "*** Apply Controller IAM Policy ***"
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

echo "*** Create IAM Role For Load Balancer Controller ***"
eksctl create iamserviceaccount \
  --cluster=${CLUSTERNAME} \
  --namespace=liatrio-time-exercise \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=arn:aws:iam::111122223333:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
