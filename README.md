# IceNetETL
Infrastructure for storing IceNet predictions and importing them into a database

# Prerequisites
You will need to install the following in order to use this package:

- `Python 3.9` (or greater)
- A [`Microsoft Azure`](https://portal.azure.com) account with at least `Contributor` permissions on the `IceNet` subscription

# Setup the Terraform backend
- Run the `Terraform` setup script `./setup_terraform.py`
- Enter the `terraform` directory with `cd terraform`
- Initialise `Terraform` by running `terraform init -backend-config=backend.secrets`
- Check the actions that `Terraform` will carry out by running `terraform plan -var-file=azure.secrets`
- Deploy using `Terraform` by running `terraform apply -var-file=azure.secrets`
