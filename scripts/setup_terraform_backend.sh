#!/bin/bash
#
# setup_terraform_backend.sh
#
# Description: This script provisions AWS infrastructure for Terraform remote state management.
# It creates an S3 bucket to store Terraform state files and a DynamoDB table to handle state locking.
#
# Author: Augment Agent
# Date: $(date +%Y-%m-%d)
#
# Usage: ./setup_terraform_backend.sh [options]
#   Options:
#     -p, --prefix PREFIX    Resource name prefix (default: "tf-state")
#     -r, --region REGION    AWS region (default: "us-east-1")
#     -f, --profile PROFILE  AWS CLI profile to use for authentication (optional)
#     -o, --output-dir DIR   Directory where backend.tf will be created (default: current directory)
#     -h, --help             Display this help message
#
# Examples:
#   ./setup_terraform_backend.sh --prefix myproject --region us-west-2
#   ./setup_terraform_backend.sh --prefix myproject --region us-west-2 --profile dev-account
#   ./setup_terraform_backend.sh --prefix myproject --region us-west-2 --output-dir ./terraform/environments/dev

set -e

# Default values
PREFIX="tf-state"
REGION="us-east-1"
PROFILE=""
OUTPUT_DIR="."
ACCOUNT_ID=""

# AWS CLI profile parameter
AWS_PROFILE_PARAM=""

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to display usage information
function display_help() {
  echo -e "${BOLD}Usage:${RESET} ./setup_terraform_backend.sh [options]"
  echo -e "${BOLD}Options:${RESET}"
  echo -e "  -p, --prefix PREFIX    Resource name prefix (default: \"tf-state\")"
  echo -e "  -r, --region REGION    AWS region (default: \"us-east-1\")"
  echo -e "  -f, --profile PROFILE  AWS CLI profile to use for authentication (optional)"
  echo -e "  -o, --output-dir DIR   Directory where backend.tf will be created (default: current directory)"
  echo -e "  -h, --help             Display this help message"
  echo -e "${BOLD}Examples:${RESET}"
  echo -e "  ./setup_terraform_backend.sh --prefix myproject --region us-west-2"
  echo -e "  ./setup_terraform_backend.sh --prefix myproject --region us-west-2 --profile dev-account"
  echo -e "  ./setup_terraform_backend.sh --prefix myproject --region us-west-2 --output-dir ./terraform/environments/dev"
}

# Function to log messages
function log() {
  local level=$1
  local message=$2
  local color=$RESET

  case $level in
    "INFO") color=$BLUE ;;
    "SUCCESS") color=$GREEN ;;
    "WARNING") color=$YELLOW ;;
    "ERROR") color=$RED ;;
  esac

  echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}${RESET}"
}

# Function to validate and prepare the output directory
function validate_output_dir() {
  # Create the directory if it doesn't exist
  if [[ ! -d "${OUTPUT_DIR}" ]]; then
    log "INFO" "Output directory '${OUTPUT_DIR}' does not exist. Creating it..."
    mkdir -p "${OUTPUT_DIR}" || {
      log "ERROR" "Failed to create output directory '${OUTPUT_DIR}'. Please check permissions."
      exit 1
    }
    log "SUCCESS" "Output directory '${OUTPUT_DIR}' created successfully."
  fi

  # Check if the directory is writable
  if [[ ! -w "${OUTPUT_DIR}" ]]; then
    log "ERROR" "Output directory '${OUTPUT_DIR}' is not writable. Please check permissions."
    exit 1
  fi

  # Convert to absolute path
  OUTPUT_DIR=$(cd "${OUTPUT_DIR}" && pwd)
  log "INFO" "Using output directory: ${OUTPUT_DIR}"
}

# Function to check if AWS CLI is installed
function check_aws_cli() {
  if ! command -v aws &> /dev/null; then
    log "ERROR" "AWS CLI is not installed. Please install it first."
    exit 1
  fi

  # Set AWS profile parameter if profile is specified
  if [[ -n "${PROFILE}" ]]; then
    AWS_PROFILE_PARAM="--profile ${PROFILE}"
    log "INFO" "Using AWS CLI profile: ${PROFILE}"
  fi

  # Check if AWS CLI is configured
  if ! aws sts get-caller-identity ${AWS_PROFILE_PARAM} &> /dev/null; then
    if [[ -n "${PROFILE}" ]]; then
      log "ERROR" "AWS CLI profile '${PROFILE}' is not configured or does not have valid credentials."
    else
      log "ERROR" "AWS CLI is not configured. Please run 'aws configure' first."
    fi
    exit 1
  fi

  # Get AWS account ID
  ACCOUNT_ID=$(aws sts get-caller-identity ${AWS_PROFILE_PARAM} --query "Account" --output text)
  log "INFO" "Using AWS Account ID: ${ACCOUNT_ID}"
}

# Function to create S3 bucket
function create_s3_bucket() {
  local bucket_name="${PREFIX}-${ACCOUNT_ID}"

  log "INFO" "Creating S3 bucket: ${bucket_name}"

  # Check if bucket already exists
  if aws s3api head-bucket --bucket "${bucket_name}" ${AWS_PROFILE_PARAM} 2>/dev/null; then
    log "WARNING" "S3 bucket '${bucket_name}' already exists."
  else
    # Create the S3 bucket
    if [[ "${REGION}" == "us-east-1" ]]; then
      aws s3api create-bucket \
        --bucket "${bucket_name}" \
        --region "${REGION}" \
        ${AWS_PROFILE_PARAM}
    else
      aws s3api create-bucket \
        --bucket "${bucket_name}" \
        --region "${REGION}" \
        --create-bucket-configuration LocationConstraint="${REGION}" \
        ${AWS_PROFILE_PARAM}
    fi

    log "SUCCESS" "S3 bucket '${bucket_name}' created successfully."
  fi

  # Enable versioning on the bucket
  log "INFO" "Enabling versioning on S3 bucket: ${bucket_name}"
  aws s3api put-bucket-versioning \
    --bucket "${bucket_name}" \
    --versioning-configuration Status=Enabled \
    ${AWS_PROFILE_PARAM}

  # Enable server-side encryption
  log "INFO" "Enabling default encryption on S3 bucket: ${bucket_name}"
  aws s3api put-bucket-encryption \
    --bucket "${bucket_name}" \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          },
          "BucketKeyEnabled": true
        }
      ]
    }' \
    ${AWS_PROFILE_PARAM}

  # Block public access
  log "INFO" "Blocking public access to S3 bucket: ${bucket_name}"
  aws s3api put-public-access-block \
    --bucket "${bucket_name}" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }' \
    ${AWS_PROFILE_PARAM}

  # Add bucket policy to enforce TLS
  log "INFO" "Adding bucket policy to enforce TLS: ${bucket_name}"
  aws s3api put-bucket-policy \
    --bucket "${bucket_name}" \
    --policy '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "EnforceTLS",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": ["arn:aws:s3:::'${bucket_name}'", "arn:aws:s3:::'${bucket_name}'/*"],
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        }
      ]
    }' \
    ${AWS_PROFILE_PARAM}

  # Return the bucket name
  echo "${bucket_name}"
}

# Function to create DynamoDB table
function create_dynamodb_table() {
  local table_name="${PREFIX}-lock"

  log "INFO" "Creating DynamoDB table: ${table_name}"

  # Check if table already exists
  if aws dynamodb describe-table --table-name "${table_name}" --region "${REGION}" ${AWS_PROFILE_PARAM} &>/dev/null; then
    log "WARNING" "DynamoDB table '${table_name}' already exists."
  else
    # Create the DynamoDB table
    aws dynamodb create-table \
      --table-name "${table_name}" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "${REGION}" \
      --tags Key=Name,Value="${table_name}" Key=Purpose,Value="Terraform state locking" \
      ${AWS_PROFILE_PARAM}

    # Wait for the table to be created
    log "INFO" "Waiting for DynamoDB table to be created..."
    aws dynamodb wait table-exists \
      --table-name "${table_name}" \
      --region "${REGION}" \
      ${AWS_PROFILE_PARAM}

    log "SUCCESS" "DynamoDB table '${table_name}' created successfully."
  fi

  # Enable point-in-time recovery
  log "INFO" "Enabling point-in-time recovery for DynamoDB table: ${table_name}"
  aws dynamodb update-continuous-backups \
    --table-name "${table_name}" \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
    --region "${REGION}" \
    ${AWS_PROFILE_PARAM}

  # Return the table name
  echo "${table_name}"
}

# Function to generate Terraform backend configuration
function generate_backend_config() {
  local bucket_name=$1
  local table_name=$2
  local config_file="${OUTPUT_DIR}/backend.tf"

  log "INFO" "Generating Terraform backend configuration: ${config_file}"

  # Start with the basic configuration
  cat > "${config_file}" << EOF
# Generated by setup_terraform_backend.sh on $(date '+%Y-%m-%d %H:%M:%S')
# This file configures the Terraform backend to use S3 for state storage and DynamoDB for state locking

terraform {
  backend "s3" {
    bucket         = "${bucket_name}"
    key            = "terraform.tfstate"
    region         = "${REGION}"
    dynamodb_table = "${table_name}"
    encrypt        = true
  }
}
EOF

  log "SUCCESS" "Terraform backend configuration generated: ${config_file}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--prefix)
      PREFIX="$2"
      shift 2
      ;;
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -f|--profile)
      PROFILE="$2"
      shift 2
      ;;
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      display_help
      exit 0
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      display_help
      exit 1
      ;;
  esac
done

# Main execution
if [[ -n "${PROFILE}" ]]; then
  log "INFO" "Starting Terraform backend setup with prefix '${PREFIX}' in region '${REGION}' using profile '${PROFILE}'"
else
  log "INFO" "Starting Terraform backend setup with prefix '${PREFIX}' in region '${REGION}'"
fi

# Check AWS CLI
check_aws_cli

# Validate output directory
validate_output_dir

# Create S3 bucket
bucket_name=$(create_s3_bucket)

# Create DynamoDB table
table_name=$(create_dynamodb_table)

# Generate backend configuration
generate_backend_config "${bucket_name}" "${table_name}"

# Output summary
log "SUCCESS" "Terraform backend setup completed successfully!"
echo -e "\n${BOLD}Summary:${RESET}"
echo -e "  ${BOLD}S3 Bucket:${RESET}     ${bucket_name}"
echo -e "  ${BOLD}S3 Bucket ARN:${RESET} arn:aws:s3:::${bucket_name}"
echo -e "  ${BOLD}DynamoDB Table:${RESET} ${table_name}"
echo -e "  ${BOLD}DynamoDB ARN:${RESET}   arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${table_name}"
echo -e "\n${BOLD}To use this backend, copy the generated 'backend.tf' file from ${OUTPUT_DIR} to your Terraform configuration directory.${RESET}"
echo -e "${BOLD}Or run 'terraform init' in the ${OUTPUT_DIR} directory to initialize the backend.${RESET}\n"
