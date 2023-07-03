resource "juju_machine" "hyperconverged" {
  count  = 0
  model  = juju_model.ovb.name
  series = local.series
  name   = "hyperconverged-${count.index}"
  constraints = "mem=8G"
}

locals {
  hyperconverged_juju_ids = [for machine in juju_machine.hyperconverged : split(":", machine.id)[1]]
}

