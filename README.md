# Quickstart

## Publish Template Spec via Azure CLI
```
$resourceGroupName = 'byteterrace';
$templateFilePath = 'resourceGroupDeployment.json';
$templateName = 'ResourceGroupDeployment';
$version = '1.0.0';

az ts create `
    --name $templateName `
    --resource-group $resourceGroupName `
    --template-file $templateFilePath `
    --version $version `
    --yes;
```

## Deploy Template Spec via Azure CLI
```
$parametersFilePath = 'resourceGroupDeployment.Parameters.json';
$resourceGroupName = 'byteterrace';
$templateFilePath = 'resourceGroupDeployment.json';
$templateName = 'ResourceGroupDeployment';
$version = '1.0.0';

$templateSpecId = (az ts show `
    --name $templateName `
    --query 'id' `
    --resource-group $resourceGroupName `
    --version $version);

az deployment group create `
    --parameters ('@{0}' -f $parametersFilePath) `
    --resource-group 'byteterrace' `
    --template-spec $templateSpecId;
```

# Useful Links
- [Azure App Service - Access Restrictions](https://docs.microsoft.com/en-us/azure/app-service/app-service-ip-restrictions/)
- [Azure App Service - Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Bastion - Network Security Groups](https://docs.microsoft.com/en-us/azure/bastion/bastion-nsg/)
- [Azure HDInsight - Business Continuity](https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-business-continuity/)
- [Azure Resource Manager - Function Functions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions/)
- [Azure Resource Manager - Naming Rules](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules/)
- [Azure Resource Manager - Template Reference](https://docs.microsoft.com/en-us/azure/templates/)
- [Azure Resource Manager - Template Specs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-specs?tabs=azure-cli)
- [Azure Resource Manager - Template Testing](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/test-toolkit)
