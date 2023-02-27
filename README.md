# IceNetETL

Infrastructure for storing IceNet predictions and importing them into a database.
This is part of the [IceNet project](https://github.com/alan-turing-institute/IceNet-Project).

## Prerequisites

You will need to install the following in order to use this package:

- A [`Microsoft Azure`](https://portal.azure.com) account with at least `Contributor` permissions on the `IceNet` subscription

* `Python 3.9` (this is the latest version supported by `Azure Functions`)

## Setup the Azure infrastructure

### Python

Install `Python` requirements with the following:

* `pip install --upgrade pip poetry`
* `poetry install`

## Setup the Terraform backend

* Run the `Terraform` setup script `./setup_terraform.py` like so: 

```
./setup_terraform.py -v \
  -i [[redacted]] \
  -s [[redacted]] \
  -g [[redacted]] \
  -rg [[redacted]] \
  -sa [[accountname]] \
  -sc [[containername]]```
```

**You can specify the environment with `-e [[ENV]]` which defaults to `dev`**

* Enter the `terraform` directory with `cd terraform`
* Initialise `Terraform` by running `terraform init` like so:

```
terraform init -backend-config=backend.secrets \
  -backend-config='storage_account_name=[[accountname]]' \
  -backend-config='container_name=[[containername]]'
```

* Check the actions that `Terraform` will carry out by running `terraform plan -var-file=azure.secrets`
* Deploy using `Terraform` by running `terraform apply -var-file=azure.secrets`

## Interfacing with IceNet pipeline

In order to process `NetCDF` files created by the [IceNet pipeline](https://github.com/antarctica/IceNet-Pipeline), these need to be uploaded to the blob storage created by the `Terraform` commands above.
Follow [the instructions here](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens) to generate tokens for the blob storage at:

* resource group: `rg-icenetetldev-data`
* storage account: `sticenetetldevdata`
* storage container: `input`

The SAS token will need: `Create`, `Write`, `Add` and `List` permissions.

### Re-triggering NetCDF processing

Every time a file is uploaded to the blob storage container it will trigger a run of the processing function.
It is possible that the processing might fail, for example if the file is malformed or the process runs out of memory.
To retry a failed run, do one of the following:

* delete the blob and then reupload it
* add metadata to the blob

Other methods are possible (for example interfacing with blob receipts) but these are more complicated.

## Providing access to raw data

In order to provide access to the `NetCDF` files stored in blob storage another SAS token will be needed.
Follow [the instructions here](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens) to generate tokens for the blob storage at:

* resource group: `rg-icenetetldev-data`
* storage account: `sticenetetldevdata`
* storage container: `input`

The SAS token will need: `Read` and `List` permissions.
