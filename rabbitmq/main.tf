terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "rabbitmq_machines" {
  count  = var.placement == null ? var.units : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "rabbitmq", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "rabbitmq" {
  model = var.model
  name  = "rabbitmq-server"
  charm {
    name    = "rabbitmq-server"
    channel = var.channel
    series  = var.series
  }

  units     = var.units
  placement = var.placement == null ? join(",", [for machine in juju_machine.rabbitmq_machines : split(":", machine.id)[1]]) : var.placement
  lifecycle {
    ignore_changes = [placement, ]
  }
}


