#!/bin/bash

export PROJECT_ID="gd-gcp-internship-devops"    
export REGION="eu-central1"           
export ZONE="eu-central1-a"        

export VPC_NAME="my-vpc"
export SUBNET_NAME="my-subnet"
export SUBNET_RANGE="10.0.0.0/24"

export VM_NAME="my-vm"
export MACHINE_TYPE="e2-medium"
export IMAGE_FAMILY="debian-11"
export IMAGE_PROJECT="debian-cloud"

export FIREWALL_RULE_NAME="allow-http"
export FIREWALL_PORT="8080"

export GCR_HOSTNAME="gcr.io"
export GCR_REPO_NAME="spring-petclinic" 

export CONTAINER_IMAGE_NAME="spring-petclinic"
export CONTAINER_TAG="latest"

export IP_NAME="my-vm-ip"
export APP_PORT="8080"


# Creating VPC
gcloud compute networks create $VPC_NAME \
    --subnet-mode=custom \
    --project=$PROJECT_ID

# Creating Subnet
gcloud compute networks subnets create $SUBNET_NAME \
    --network=$VPC_NAME \
    --range=$SUBNET_RANGE \
    --region=$REGION \
    --project=$PROJECT_ID

# Creating Firewall Rule
gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
    --network=$VPC_NAME \
    --allow=tcp:$FIREWALL_PORT \
    --target-tags=http-server \
    --direction=INGRESS \
    --priority=1000 \
    --project=$PROJECT_ID

# Reserve a static external IP address
gcloud compute addresses create $IP_NAME \
    --region=$REGION \
    --project=$PROJECT_ID

# Create the VM instance
gcloud compute instances create $VM_NAME \
    --machine-type=$MACHINE_TYPE \
    --subnet=$SUBNET_NAME \
    --zone=$ZONE \
    --tags=http-server \
    --address=$(gcloud compute addresses describe $IP_NAME --region=$REGION --format="get(address)") \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --project=$PROJECT_ID


# Authenticate with GCR
gcloud auth configure-docker $GCR_HOSTNAME

# Tag the Docker image
docker tag $CONTAINER_IMAGE_NAME:$CONTAINER_TAG $GCR_HOSTNAME/$PROJECT_ID/$GCR_REPO_NAME:$CONTAINER_TAG

# Push the Docker image to GCR
docker push $GCR_HOSTNAME/$PROJECT_ID/$GCR_REPO_NAME:$CONTAINER_TAG


# Update package index and install Docker
sudo apt-get update
sudo apt-get install -y docker.io

# Authenticate Docker to use GCR
gcloud auth configure-docker

# Pull the Docker image from GCR
docker pull $GCR_HOSTNAME/$PROJECT_ID/$GCR_REPO_NAME:$CONTAINER_TAG

# Run the container
docker run -d -p $APP_PORT:8080 $GCR_HOSTNAME/$PROJECT_ID/$GCR_REPO_NAME:$CONTAINER_TAG

EOF


# Get the external IP address of the VM
EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME \
    --zone=$ZONE \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
    --project=$PROJECT_ID)
