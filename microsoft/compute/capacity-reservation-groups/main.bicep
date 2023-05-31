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
resource capacityReservations 'Microsoft.Compute/capacityReservationGroups/capacityReservations@2023-03-01' = [for reservation in sort(items(properties.?reservations ?? {}), (x, y) => (x.key < y.key)): {
  location: location
  name: reservation.key
  parent: capacityReservationGroup
  sku: reservation.value.sku
  tags: (reservation.value.?tags ?? tags)
  zones: (reservation.value.?availabilityZones ?? null)
}]
