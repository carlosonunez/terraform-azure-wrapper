#!/usr/bin/env bash
if [ "$1" == '--create-env' ]
then
  if test -f "$PWD/.env" && test "$2" != "--force"
  then
    >&2 echo "ERROR: You already have an environment file; add --force to overwrite it."
    exit 1
  fi
  ./scripts/create_env.sh &&
  cat <<-CREATE_ENV_INSTRUCTIONS
A new environment file has been created at $PWD/.env. The contents of this file
are shown below. Open it in an editor and change anything that says 'change me.'

$(cat $PWD/.env)
CREATE_ENV_INSTRUCTIONS
  exit 0
fi

AZURE_TENANT_ID="${AZURE_TENANT_ID?Please provide the ID for your Azure tenant.}"
AZURE_CLIENT_ID="${AZURE_CLIENT_ID?Please provide the ID for your Azure service principal.}"
AZURE_CLIENT_PASSWORD="${AZURE_CLIENT_PASSWORD?Please provide the secret for AZURE_CLIENT_ID.}"
AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID?Please provide the ID \
for the subscription that Terraform will store its state into.}"
TERRAFORM_STATE_STORAGE_ACCOUNT_NAME="${TERRAFORM_STATE_STORAGE_ACCOUNT_NAME?Please provide \
the name of the storage account that will be saving Terraform state.}"
TERRAFORM_STATE_STORAGE_CONTAINER_NAME="${TERRAFORM_STATE_STORAGE_CONTAINER_NAME?Please provide \
the name of the storage container to store state into.}"
TERRAFORM_STATE_RESOURCE_GROUP_NAME="${TERRAFORM_STATE_RESOURCE_GROUP_NAME?Please provide \
the name of the resource group in which the storage account resides.}"
TERRAFORM_STATE_NAME="${TERRAFORM_STATE_NAME:-terraform.tfstate}"

run_preflight_checks_or_exit() {
  login_to_azure() {
    az login --service-principal \
      --username "$AZURE_CLIENT_ID" \
      --password "$AZURE_CLIENT_PASSWORD" \
      --tenant "$AZURE_TENANT_ID" \
      --output none
  }

  confirm_resource_group_exists() {
    if ! az group list --subscription "$AZURE_SUBSCRIPTION_ID" \
      --query [].name \
      --output tsv | \
      grep -q "$TERRAFORM_STATE_RESOURCE_GROUP_NAME"
    then
      >&2 echo "ERROR: Resource group [$TERRAFORM_STATE_RESOURCE_GROUP_NAME] does not \
exist in Azure subscription [$AZURE_SUBSCRIPTION_ID]. Run this Azure CLI \
command to fix this:

az group greate --subscription $AZURE_SUBSCRIPTION_ID \
--name $TERRAFORM_STATE_RESOURCE_GROUP_NAME \
--location YOUR_LOCATION"
      return 1
    fi
  }

  confirm_storage_account_exists() {
    if ! az storage account list --subscription "$AZURE_SUBSCRIPTION_ID" \
      --query [].name \
      --output tsv | \
        grep -q "$TERRAFORM_STATE_STORAGE_ACCOUNT_NAME"
    then
      >&2 echo "ERROR: Storage account [$TERRAFORM_STATE_STORAGE_ACCOUNT_NAME] does not \
exist in Azure subscription [$AZURE_SUBSCRIPTION_ID]. Run this Azure CLI \
command to fix this:

az storage account create --subscription $AZURE_SUBSCRIPTION_ID \
--name $TERRAFORM_STATE_STORAGE_ACCOUNT_NAME -g $TERRAFORM_STATE_RESOURCE_GROUP_NAME \
--location YOUR_LOCATION \
--sku STORAGE_ACCOUNT_SKU."
      return 1
    fi
  }

  confirm_storage_container_exists() {
    if ! 2>/dev/null az storage container show \
      --account-name "$TERRAFORM_STATE_STORAGE_ACCOUNT_NAME" \
      --name "$TERRAFORM_STATE_STORAGE_CONTAINER_NAME" \
      --subscription "$AZURE_SUBSCRIPTION_ID" \
      --auth-mode "login" \
      --output none
    then
      >&2 echo "ERROR: Container [$TERRAFORM_STATE_STORAGE_CONTAINER_NAME] does not exist in \
storage account [$TERRAFORM_STATE_STORAGE_ACCOUNT_NAME] within \
Azure subscription [$AZURE_SUBSCRIPTION_ID]. Run this Azure CLI \
command (after running 'az login') to fix this:

az storage container create --subscription $AZURE_SUBSCRIPTION_ID \
--auth-mode login \
--name $TERRAFORM_STATE_STORAGE_CONTAINER_NAME  \
--account-name $TERRAFORM_STATE_STORAGE_ACCOUNT_NAME"
      return 1
    fi
  }

  login_to_azure &&
    confirm_resource_group_exists &&
    confirm_storage_account_exists &&
    confirm_storage_container_exists
}

configure_environment() {
  export ARM_CLIENT_ID=$AZURE_CLIENT_ID
  export ARM_CLIENT_SECRET=$AZURE_CLIENT_PASSWORD
  export ARM_TENANT_ID=$AZURE_TENANT_ID
  export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
}

initialize_terraform() {
  terraform init -input=false \
    -backend-config="storage_account_name=$TERRAFORM_STATE_STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=$TERRAFORM_STATE_STORAGE_CONTAINER_NAME" \
    -backend-config="key=$TERRAFORM_STATE_NAME" \
    -backend-config="resource_group_name=$TERRAFORM_STATE_RESOURCE_GROUP_NAME"
}

run_terraform_action() {
  echo not_yet
}

run_preflight_checks_or_exit &&
  configure_environment &&
  initialize_terraform &&
  run_terraform_action $*
