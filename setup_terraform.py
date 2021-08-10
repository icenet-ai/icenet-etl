#! /usr/bin/env python3
import argparse
import coloredlogs
import logging
import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.mgmt.subscription import SubscriptionClient
from azure.mgmt.storage import StorageManagementClient


def main():
    """Setup initial Azure infrastructure used by Terraform"""
    # Disable unnecessarily verbose Azure logging
    logging.getLogger("azure.identity._internal").setLevel(logging.ERROR)
    logging.getLogger("azure.identity._credentials").setLevel(logging.ERROR)
    logging.getLogger("azure.core.pipeline.policies").setLevel(logging.ERROR)

    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description="Initialise the Azure infrastructure needed by Terraform"
    )
    parser.add_argument(
        "-s",
        "--azure-subscription",
        type=str,
        default="a908aa7c-f906-4b57-b451-cb5023f5bd5c",
        help="Name or ID for the Azure subscription being used.",
    )
    parser.add_argument(
        "-g",
        "--resource-group",
        type=str,
        default="rg-icenetetl-terraform",
        help="Name of the resource group where the Terraform backend will be stored",
    )
    parser.add_argument(
        "-a",
        "--storage-account",
        type=str,
        default="sticenetetlterraform",
        help="Name of the storage account where the Terraform backend will be stored",
    )
    parser.add_argument(
        "-c",
        "--storage-container",
        type=str,
        default="blob-icenetetl-terraform",
        help="Name of the storage container where the Terraform backend will be stored",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="count",
        default=0,
        help="Verbosity level. Default is WARNING and above.",
    )

    # Configure logging, increasing verbosity by one level for each 'v'
    args = parser.parse_args()
    verbosity = max(logging.WARNING - (10 * args.verbose), 0)
    coloredlogs.install(fmt="%(asctime)s %(levelname)8s: %(message)s", level=verbosity)

    # Configure the Terraform backend
    configure_terraform_backend(
        args.azure_subscription,
        args.resource_group,
        args.storage_account,
        args.storage_container,
    )
    storage_key = load_terraform_storage_key(
        args.azure_subscription, args.resource_group, args.storage_account
    )

    # Write Terraform backend config to file
    config_path = os.path.join("terraform", "backend.tf")
    write_backend_configuration(
        config_path, args.storage_account, args.storage_container, storage_key
    )


def write_backend_configuration(config_path, account_name, container_name, account_key):
    """Write Terraform backend configuration"""
    logging.info(f"Writing Terraform backend config to {config_path}")
    state_file_name = "terraform.tfstate"
    config_lines = [
        "terraform {",
        '    backend "azurerm" {',
        f'        access_key           = "{account_key}"',
        f'        container_name       = "{container_name}"',
        f'        key                  = "{state_file_name}"',
        f'        storage_account_name = "{account_name}"',
        "    }",
        "}",
    ]
    with open(config_path, "w") as f_out:
        f_out.writelines(map(lambda l: l + "\n", config_lines))


def configure_terraform_backend(
    subscription_id,
    resource_group_name,
    storage_account_name,
    storage_container_name,
    location="uksouth",
):
    """Ensure that Terraform backend resources are configured"""
    credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)

    # Create Azure clients
    resource_client = ResourceManagementClient(
        credential=credential, subscription_id=subscription_id
    )
    subscription_client = SubscriptionClient(
        credential=credential, subscription_id=subscription_id
    )
    storage_client = StorageManagementClient(
        credential=credential, subscription_id=subscription_id
    )

    # Check that the Azure credentials are valid
    try:
        for subscription in subscription_client.subscriptions.list():
            logging.debug(
                f"Found subscription {subscription.display_name} ({subscription.id})"
            )
        logging.info(
            f"Successfully authenticated using: {credential._successful_credential.__class__.__name__}"
        )
    except ClientAuthenticationError:
        logging.error(
            "Failed to authenticate with Azure! Please ensure that you can use one of the methods below:"
        )
        raise

    # Ensure that resource group exists
    logging.info(f"Ensuring that resource group {resource_group_name} exists...")
    resource_client.resource_groups.create_or_update(
        resource_group_name, {"location": location, "tags": {"component": "icenetetl"}}
    )
    for resource_group in filter(
        lambda group: group.name == resource_group_name,
        resource_client.resource_groups.list(),
    ):
        logging.info(
            f"Found resource group {resource_group.name} in {resource_group.location}"
        )

    # Ensure that storage account exists
    logging.info(f"Ensuring that storage account {storage_account_name} exists...")
    try:
        poller = storage_client.storage_accounts.begin_create(
            resource_group_name,
            storage_account_name,
            {
                "location": location,
                "kind": "StorageV2",
                "sku": {"name": "Standard_LRS"},
                "tags": {"component": "icenetetl"},
            },
        )
        storage_account = poller.result()
        logging.info(
            f"Found storage account {storage_account.name} in {storage_account.location}"
        )
    except HttpResponseError:
        logging.error("Failed to create storage account {storage_account_name}!")
        raise

    # Ensure that storage container exists
    logging.info(f"Ensuring that storage container {storage_container_name} exists...")
    try:
        container = storage_client.blob_containers.create(
            resource_group_name,
            storage_account_name,
            storage_container_name,
            {"public_access": "none"},
        )
        logging.info(f"Found storage container {container.name}")
    except HttpResponseError:
        logging.error("Failed to create storage account {storage_account_name}!")
        raise


def load_terraform_storage_key(
    subscription_id,
    resource_group_name,
    storage_account_name,
):
    """Load Terraform backend resources are configured"""
    credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)

    # Create Azure clients
    storage_client = StorageManagementClient(
        credential=credential, subscription_id=subscription_id
    )

    """Ensure that Terraform backend resources are configured"""
    # Return the first storage account key
    storage_keys = storage_client.storage_accounts.list_keys(
        resource_group_name, storage_account_name
    )
    return storage_keys.keys[0].value


if __name__ == "__main__":
    main()
