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

echo "*** Update Kube-Config For EKS ***"
aws eks update-kubeconfig --region us-east-1 --name=${CLUSTERNAME}

echo "*** Create Kubernetes Namespace"
kubectl create namespace liatrio-time-exercise

echo "*** Deploy Container To EKS Cluster ***"
kubectl apply -f deployment.yaml

echo "*** Deploy Service To EKS Cluster ***"
kubectl apply -f service.yaml

echo "*** Download IAM Policy For Load Balancer Controller ***"
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

echo "*** Apply Controller IAM Policy ***"
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

echo "*** Sleep for 2 minutes ***"
sleep 2m

echo "*** Create IAM Role For Load Balancer Controller ***"
eksctl create iamserviceaccount \
--cluster=${CLUSTERNAME} \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--role-name "AmazonEKSLoadBalancerControllerRole" \
--attach-policy-arn=arn:aws:iam::798870450882:policy/AWSLoadBalancerControllerIAMPolicy \
--approve \
--override-existing-serviceaccounts

echo "*** Install Cert Manager ***"
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

echo "*** Add wait ***"

kubectl wait \
  --request-timeout=300s \
  -n cert-manager \
  --for=condition=Available deployment/cert-manager-webhook


echo "*** Download Controller Manifest ***"
curl -Lo v2_4_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml
if [ $? -eq 0 ]; then
   echo "Download Ok"
else 
   echo "Download Failed"
fi

echo "*** Remove Sevice Account Section From Manifest ***"
sed -i.bak -e '480,488d' ./v2_4_4_full.yaml
if [ $? -eq 0 ]; then
   echo "Replacement In Manifest Succeeded"
else
   echo "Replacement In Manifest Failed"
fi

echo "*** Add Cluster Name To Manifest ***"
sed -i.bak -e "s|your-cluster-name|${CLUSTERNAME}|" ./v2_4_4_full.yaml
if [ $? -eq 0 ]; then
   echo "Adding Cluster Name To Manifest Succeeded"
else
   echo "Adding Cluster Name To Manifest Failed"
fi

echo "*** Deploy Controller Manifest ***"
kubectl apply -f v2_4_4_full.yaml

echo "*** Download IngressClass and IngressClassParams Manifest ***"
curl -Lo v2_4_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_ingclass.yaml
if [ $? -eq 0 ]; then
   echo "Ingress Manifests Downloaded Successfully"
else
   echo "Ingress Manifests Failed to Download"
fi

echo " *** Apply Ingress Manifests to Cluster ***"
kubectl apply -f v2_4_4_ingclass.yaml

echo "*** Apply Ingress.yaml ***"
kubetl apply -f ingress.yaml
	
echo "*** Verify Controller is Installed ***"
kubectl get deployment -n kube-system aws-load-balancer-controller
