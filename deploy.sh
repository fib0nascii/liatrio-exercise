#!/usr/bin/env bash

echo "*** Begin Deployment ***"

usage() {
  echo "(AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY) to be set"
  exit 1
}

if [ ${#} -ne 2 ] ; then
  usage
fi

echo "*** Launching Environment ***"

cd terraform
terraform init
terraform plan -out out.terraform
terraform apply out.terraform

echo "*** Build Docker Image ***"
docker build . -t liatrio-time-exercise


