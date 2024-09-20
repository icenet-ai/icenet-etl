# IceNetETL

Infrastructure for storing IceNet predictions and importing them into a database.
This is part of the [IceNet project](https://github.com/alan-turing-institute/IceNet-Project).

## Prerequisites

You will need to install the following in order to use this package:

- A [`Microsoft Azure`](https://portal.azure.com) account with at least `Contributor` permissions on the `IceNet` subscription

* `Python 3.8` or above

## Setup the Azure infrastructure

### Python

Install `Python` requirements with the following:

* `pip install --upgrade pip setuptools wheel`
* `pip install -r requirements.txt`

### Setup the Terraform backend

* Run the `Terraform` setup script `./setup_terraform.py` like so:

```
./setup_terraform.py -v \
  -i [[admin_subnets]] \
  -s [[subscription_name]] \
  -rg [[state_resourcegroupname]] \
  -sa [[state_accountname]] \
  -sc [[state_containername]] \
  [[docker_login]] \
  [[notification_email]]
```

**You can specify the environment with `-e [[ENV]]` which defaults to `dev`**

* Enter the `terraform` directory with `cd terraform`
* Initialise `Terraform` by running `terraform init` like so:

```
terraform init -backend-config=backend.[[ENV]].secrets \
  -backend-config='storage_account_name=[[state_accountname]]' \
  -backend-config='container_name=[[state_containername]]'
```

### Running terraform

* Check the actions that `Terraform` will carry out by running `terraform plan -var-file=azure.[[ENV]].secrets`
* Deploy using `Terraform` by running `terraform apply -var-file=azure.[[ENV]].secrets`
* Switch environments by calling `terraform init` again

**Note that a full run from fresh will likely fail and the apply need rerunning, because we've not sorted all the resource chaining out yet**

#### NOTE: deploy InputBlobTrigger

This is a WIP issue, the processing application needs to be deployed before a final run to deploy a function app that can be
targeted by the event grid subscription. See [this github issue](https://github.com/icenet-ai/icenet-etl/issues/43)

### Provision email domain, connect and add to configuration

This is not achievable via the terraform provider yet, so you'll need to provision the email domain for sending manually,
connect it to the comms provider and then add the notification_email address to the `azure.[[ENV]].secrets` file.

### Interfacing with IceNet pipeline

In order to process `NetCDF` files created by the [IceNet pipeline](https://github.com/icenet-ai/icenet-pipeline), these need to be uploaded to the blob storage created by the `Terraform` commands above.
Follow [the instructions here](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens) to generate tokens for the blob storage at:

* resource group: `rg-icenet[[ENV]]-data`
* storage account: `sticenet[[ENV]]data`
* storage container: `input`

The SAS token will need: `Create`, `Write`, `Add` and `List` permissions.

### Re-triggering NetCDF processing

Every time a file is uploaded to the blob storage container it will trigger a run of the processing function.
It is possible that the processing might fail, for example if the file is malformed or the process runs out of memory.
To retry a failed run, do one of the following:

* delete the blob and then reupload it
* add metadata to the blob

Other methods are possible (for example interfacing with blob receipts) but these are more complicated.

### Providing access to raw data

In order to provide access to the `NetCDF` files stored in blob storage another SAS token will be needed.
Follow [the instructions here](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens) to generate tokens for the blob storage at:

* resource group: `rg-icenet[[ENV]]-data`
* storage account: `sticenet[[ENV]]data`
* storage container: `input`

The SAS token will need: `Read` and `List` permissions.

## Application deployment

`make deploy-azure` basically deploys each of the applications from each of these repositories

* icenet-geoapi: secrets file is output to repository if variable is set, 
* icenet-geoapi-processing: deployment to the function app is manual, which will be required as mentioned above
* icenet-event-processor: this is deployed from docker or updated in the container if using dev
* icenet-application: this is deployed from github using deploy/sync via a source manual integration

This needs to be done manually, because with a properly configured perimeter this will be delegated to a secure internal host. If this were in terraform, it would make the implementation much more of a mission!

## Other deployment instructions

The following are noted from a recent deployment

You have to provision manually the email domain on icenet[ENV]-emails
Then connect the icenet[ENV]-emails service to icenet[ENV]-comms

Then you need to deploy the applications

  icenet-geoapi-processing
  1. `export ICENET_ENV=uat`
  2. `make deploy-azure`

  icenet-application
  1. `export ICENET_ENV=uat`
  2. `make deploy-azure` - from https://github.com/icenet-ai/icenet-application
    OR
  2. `make deploy-zip` - from the local clone

  icenet-event-processor
  1. In theory deploys from the docker registry image

## Versioning

There's no incremental versioning at present.

v0.0.1 refers to the ongoing development until we move into demo usage, at which point this will
be reviewed...

## Credits

<a href="https://github.com/icenet-ai/icenet-etl/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=icenet-ai/icenet-etl" />
</a>

## License

This is licensed using the [MIT License](LICENSE)
