param location string = resourceGroup().location
param name string
@secure()
param properties object
param tags object = {}

resource capacityReservationGroup 'Microsoft.Compute/capacityReservationGroups@2023-03-01' = {
  location: location
  name: name
  tags: tags
  zones: (properties.?availabilityZones ?? null)
}
resource capacityReservations 'Microsoft.Compute/capacityReservationGroups/capacityReservations@2023-03-01' = [for reservation in (properties.?capacityReservations ?? []): {
  location: location
  name: reservation.name
  parent: capacityReservationGroup
  sku: reservation.sku
  tags: (reservation.?tags ?? tags)
  zones: (reservation.?availabilityZones ?? null)
}]
