#!/bin/bash
#
# teardown_terraform_backend.sh
#
# Description: This script tears down AWS infrastructure for Terraform remote state management.
# It deletes the S3 bucket (including all objects) and DynamoDB table created by the setup script.
#
# Author: Augment Agent
# Date: $(date +%Y-%m-%d)
#
# Usage: ./teardown_terraform_backend.sh [options]
#   Options:
#     -p, --prefix PREFIX    Resource name prefix (default: "tf-state")
#     -r, --region REGION    AWS region (default: "us-east-1")
#     -f, --profile PROFILE  AWS CLI profile to use for authentication (optional)
#     -o, --output-dir DIR   Directory where backend.tf was created (default: current directory)
#     -h, --help             Display this help message
#
# Examples:
#   ./teardown_terraform_backend.sh --prefix myproject --region us-west-2
#   ./teardown_terraform_backend.sh --prefix myproject --region us-west-2 --profile dev-account
#   ./teardown_terraform_backend.sh --prefix myproject --region us-west-2 --output-dir ./terraform/environments/dev

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
  echo -e "${BOLD}Usage:${RESET} ./teardown_terraform_backend.sh [options]"
  echo -e "${BOLD}Options:${RESET}"
  echo -e "  -p, --prefix PREFIX    Resource name prefix (default: \"tf-state\")"
  echo -e "  -r, --region REGION    AWS region (default: \"us-east-1\")"
  echo -e "  -f, --profile PROFILE  AWS CLI profile to use for authentication (optional)"
  echo -e "  -o, --output-dir DIR   Directory where backend.tf was created (default: current directory)"
  echo -e "  -h, --help             Display this help message"
  echo -e "${BOLD}Examples:${RESET}"
  echo -e "  ./teardown_terraform_backend.sh --prefix myproject --region us-west-2"
  echo -e "  ./teardown_terraform_backend.sh --prefix myproject --region us-west-2 --profile dev-account"
  echo -e "  ./teardown_terraform_backend.sh --prefix myproject --region us-west-2 --output-dir ./terraform/environments/dev"
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

# Function to validate the output directory and handle backend.tf
function validate_output_dir() {
  # Check if the directory exists
  if [[ ! -d "${OUTPUT_DIR}" ]]; then
    log "WARNING" "Output directory '${OUTPUT_DIR}' does not exist."
    return
  fi

  # Convert to absolute path
  OUTPUT_DIR=$(cd "${OUTPUT_DIR}" && pwd)
  log "INFO" "Using output directory: ${OUTPUT_DIR}"

  # Check if backend.tf exists in the output directory
  local backend_file="${OUTPUT_DIR}/backend.tf"
  if [[ -f "${backend_file}" ]]; then
    log "INFO" "Found backend.tf file in ${OUTPUT_DIR}"

    # Ask if the user wants to remove it
    read -p "$(echo -e "${YELLOW}Do you want to remove the backend.tf file? (y/n): ${RESET}")" confirm
    if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
      rm "${backend_file}"
      log "SUCCESS" "Removed backend.tf file from ${OUTPUT_DIR}"
    else
      log "INFO" "Keeping backend.tf file in ${OUTPUT_DIR}"
    fi
  else
    log "INFO" "No backend.tf file found in ${OUTPUT_DIR}"
  fi
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

# Function to delete S3 bucket
function delete_s3_bucket() {
  local bucket_name="${PREFIX}-${ACCOUNT_ID}"

  log "INFO" "Checking if S3 bucket exists: ${bucket_name}"

  # Check if bucket exists
  if ! aws s3api head-bucket --bucket "${bucket_name}" ${AWS_PROFILE_PARAM} 2>/dev/null; then
    log "WARNING" "S3 bucket '${bucket_name}' does not exist or you don't have access to it."
    return
  fi

  # Confirm deletion
  read -p "$(echo -e "${YELLOW}Are you sure you want to delete the S3 bucket '${bucket_name}' and all its contents? (y/n): ${RESET}")" confirm
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    log "INFO" "Skipping deletion of S3 bucket '${bucket_name}'."
    return
  fi

  # Empty the bucket first
  log "INFO" "Emptying S3 bucket: ${bucket_name}"
  aws s3 rm s3://${bucket_name} --recursive ${AWS_PROFILE_PARAM}

  # Delete the bucket
  log "INFO" "Deleting S3 bucket: ${bucket_name}"
  aws s3api delete-bucket --bucket "${bucket_name}" ${AWS_PROFILE_PARAM}

  log "SUCCESS" "S3 bucket '${bucket_name}' deleted successfully."
}

# Function to delete DynamoDB table
function delete_dynamodb_table() {
  local table_name="${PREFIX}-lock"

  log "INFO" "Checking if DynamoDB table exists: ${table_name}"

  # Check if table exists
  if ! aws dynamodb describe-table --table-name "${table_name}" --region "${REGION}" ${AWS_PROFILE_PARAM} &>/dev/null; then
    log "WARNING" "DynamoDB table '${table_name}' does not exist or you don't have access to it."
    return
  fi

  # Confirm deletion
  read -p "$(echo -e "${YELLOW}Are you sure you want to delete the DynamoDB table '${table_name}'? (y/n): ${RESET}")" confirm
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    log "INFO" "Skipping deletion of DynamoDB table '${table_name}'."
    return
  fi

  # Delete the table
  log "INFO" "Deleting DynamoDB table: ${table_name}"
  aws dynamodb delete-table --table-name "${table_name}" --region "${REGION}" ${AWS_PROFILE_PARAM}

  # Wait for the table to be deleted
  log "INFO" "Waiting for DynamoDB table to be deleted..."
  aws dynamodb wait table-not-exists --table-name "${table_name}" --region "${REGION}" ${AWS_PROFILE_PARAM}

  log "SUCCESS" "DynamoDB table '${table_name}' deleted successfully."
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
  log "INFO" "Starting Terraform backend teardown with prefix '${PREFIX}' in region '${REGION}' using profile '${PROFILE}'"
else
  log "INFO" "Starting Terraform backend teardown with prefix '${PREFIX}' in region '${REGION}'"
fi

# Check AWS CLI
check_aws_cli

# Validate output directory and handle backend.tf
validate_output_dir

# Display warning
echo -e "\n${RED}${BOLD}WARNING:${RESET} ${RED}This script will delete the following resources:${RESET}"
echo -e "  ${BOLD}S3 Bucket:${RESET}     ${PREFIX}-${ACCOUNT_ID}"
echo -e "  ${BOLD}DynamoDB Table:${RESET} ${PREFIX}-lock"
echo -e "\n${RED}${BOLD}This action is irreversible and will result in the loss of all Terraform state files!${RESET}\n"

# Final confirmation
read -p "$(echo -e "${RED}Are you absolutely sure you want to proceed? (yes/no): ${RESET}")" final_confirm
if [[ "${final_confirm}" != "yes" ]]; then
  log "INFO" "Teardown cancelled."
  exit 0
fi

# Delete resources
delete_s3_bucket
delete_dynamodb_table

# Output summary
log "SUCCESS" "Terraform backend teardown completed successfully!"
echo -e "\n${BOLD}Summary:${RESET}"
echo -e "  ${BOLD}S3 Bucket:${RESET}     ${PREFIX}-${ACCOUNT_ID} (deleted)"
echo -e "  ${BOLD}DynamoDB Table:${RESET} ${PREFIX}-lock (deleted)"
echo -e "\n${BOLD}Your Terraform backend resources have been removed.${RESET}\n"
