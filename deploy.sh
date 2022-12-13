#!/usr/bin/env bash

echo "*** Begin Deployment ***"

echo "*** Launching Environment ***"

cd terraform
terraform init
terraform plan -out out.terraform
terraform apply out.terraform

echo "*** Build Docker Image ***"
cd ..
docker build . -t 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo:latest

echo "*** Login To ECR ***"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo

echo "*** Push Docker Image To ECR ***"
docker push 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo:latest

echo "*** Get EKS Cluster Name ***"
CLUSTERNAME=$(eksctl get cluster --output=json | jq -r '.[].Name')
echo ${CLUSTERNAME}

echo "*** Update Kube-Config for EKS ***"
aws eks update-kubeconfig --region us-east-1 --name=${CLUSTERNAME}

echo "*** Create Kubernetes Namespace"
kubectl create namespace liatrio-time-exercise

echo "*** Deploy App To Kubernetes ***"
