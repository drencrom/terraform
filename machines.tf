resource "juju_machine" "machines" {
  count  = 0
  model  = juju_model.ovb.name
  series = local.series
  name   = count.index
}

locals {
  juju_ids = [for machine in juju_machine.machines : split(":", machine.id)[1]]
}
