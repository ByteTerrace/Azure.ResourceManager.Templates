param resources array

output ids array = [for resource in resources: {
    id: resourceId(union({
        subscriptionId: subscription().subscriptionId
    }, resource).subscriptionId, union({
        resourceGroupName: resourceGroup().name
    }, resource).resourceGroupName, resource.type, resource.name)
}]
