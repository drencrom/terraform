terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "mysql_machines" {
  count  = var.placement == null ? var.units : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "cinder", count.index)
  constraints = "mem=4G"
}

resource "juju_application" "mysql_innodb_cluster" {
  model = var.model
  name  = "mysql-innodb-cluster" # Needed the name or you get an error about how application- is an invalid application tag
  charm {
    name    = "mysql-innodb-cluster"
    channel = var.channel
    series  = var.series
  }

  units     = var.units
  placement = var.placement == null ? join(",", [for machine in juju_machine.mysql_machines : split(":", machine.id)[1]]) : var.placement
  lifecycle {
    ignore_changes = [placement, ]
  }
}

