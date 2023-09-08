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

**Function applications - deployment notes**
https://github.com/hashicorp/terraform-provider-azurerm/issues/10990
https://gmusumeci.medium.com/using-private-endpoint-in-azure-storage-account-with-terraform-49b4734ada34

## Notes

Had to register the comms provider: az provider register --namespace "Microsoft.Communication"

## Architectural Design

Applications are deployed only once the infrastructure is in place, separation of concerns
and far easier to manage with securing of the network structure
