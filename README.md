# IceNetETL

Infrastructure for storing IceNet predictions and importing them into a database

# Prerequisites

You will need to install the following in order to use this package:

- A [`Microsoft Azure`](https://portal.azure.com) account with at least `Contributor` permissions on the `IceNet` subscription
- `Python 3.9` (this is the latest version supported by `Azure Functions`)

## Python

Install `Python` requirements with the following:

- `pip install --upgrade pip poetry`
- `poetry install`

# Setup the Terraform backend

- Run the `Terraform` setup script `./setup_terraform.py`
- Enter the `terraform` directory with `cd terraform`
- Initialise `Terraform` by running `terraform init -backend-config=backend.secrets`
- Check the actions that `Terraform` will carry out by running `terraform plan -var-file=azure.secrets`
- Deploy using `Terraform` by running `terraform apply -var-file=azure.secrets`
