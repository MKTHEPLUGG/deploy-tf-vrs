#!/bin/sh -l

# Initialize Terraform
terraform init \
    -backend-config="storage_account_name=$1" \
    -backend-config="container_name=$2" \
    -backend-config="key=$3" \
    -backend-config="resource_group_name=$4" \
    -backend-config="client_id=$5" \
    -backend-config="client_secret=$6" \
    -backend-config="tenant_id=$7"

# Validate, Plan, and Apply
terraform validate && terraform plan && terraform apply -auto-approve
