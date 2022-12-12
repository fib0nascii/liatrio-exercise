#!/usr/bin/env bash

echo "*** Begin Deployment ***"

#usage() {
#  echo "(AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY) to be set"
#  exit 1
#}
#
#if [[ ${#} -ne 2 ]] ; then
#  usage
#fi

echo "*** Launching Environment ***"

cd terraform
terraform init
terraform plan -out out.terraform
terraform apply out.

echo "*** Build Docker Image ***"
cd ..
docker build . -t 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo:latest

echo "*** Login To ECR ***"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo

echo "*** Push Docker Image To ECR ***"
docker push 798870450882.dkr.ecr.us-east-1.amazonaws.com/liatrio-exercise-repo:latest

echo "*** Create Kubernetes Namespace"

echo "*** Deploy App To Kubernetes ***"