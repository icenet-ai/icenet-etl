
### Dev tasklist

The following tasks and testing need to be undertaken to ensure that the `dev`
branch encompasses the needs of these projects. This needs moving into GH#31

* [x] Ensure project suffix is usable for "client" installations of ETL, defaults to `icenet`: removed from diagram
* [ ] Address TODO: topic subscriptions setup
* [ ] Sort out app-icenet-pygeoapi application deployment
* [ ] Configure lb-icenet-interface for public IP usage
  * [ ] Set up NSG and https access via lb-icenet-interface
  * [ ] Set up ASG between lb-icenet-interface and pygeoapi / assets
  * [ ] Set up ASG between pygeoapi / assets and `processing` storage account
  * [ ] Set up dev.icenet.ai to point to this interface
* [ ] Deploy infrastructure to dev
  * [ ] Configure email communications setup for icenet-comms
  * [ ] Update email address configuraton in app-icenet-event-processor
* [ ] Grab SAS token and ensure capability to upload to input from admin sources
* [ ] Check that non-admin IP sources cannot upload (test admin NSG)

Tests:
* [ ] Verify icenet-forecast-topic event triggers app-icenet-event-processor
  * [ ] Verify email sent
* [ ] Verify app-icenet-processing processes on input
  * [ ] Verify database records inserted into psql-icenet-database
  * [ ] Verify event deposited on icenet-processing-topic
  * [ ] Verify icenet-processing-topic even triggers app-icenet-event-processor
* [ ] Verify app-icenet-pygeoapi can view data from database
  * [ ] Run notebook for simplistic test
* [ ] Verify access via lb-icenet-interface
* [ ] Produce op assets and upload to `processing` container
  * [ ] Set up tasks to develop initial dashboard based on these
  * [ ] Set up tasks to develop initial API access for these

### Microsoft notes of use
https://learn.microsoft.com/en-us/azure/architecture/example-scenario/apps/fully-managed-secure-apps
https://github.com/Azure/fta-internalbusinessapps/blob/master/appmodernization/app-service-environment/ase-walkthrough.md

--> https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/enterprise-integration/ase-standard-deployment

**These were module specific, but condensed in here to avoid too many crazy readmes...**
assets/README.md
https://learn.microsoft.com/en-us/azure/app-service/scripts/terraform-secure-backend-frontend
data/README.md
https://github.com/hashicorp/terraform-provider-azurerm/issues/8534#issuecomment-765735093
https://docs.microsoft.com/en-us/azure/postgresql/concepts-data-access-and-security-private-link
https://learn.microsoft.com/en-us/azure/security/fundamentals/paas-applications-using-sql
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint
https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource
processing/README.md
https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration
pygeoapi/README.md
https://learn.microsoft.com/en-us/azure/app-service/scripts/terraform-secure-backend-frontend
web/README.md
https://learn.microsoft.com/en-us/azure/app-service/quickstart-python?tabs=flask%2Cwindows%2Cazure-cli%2Cazure-cli-deploy%2Cdeploy-instructions-azportal%2Cterminal-bash%2Cdeploy-instructions-zip-azcli
