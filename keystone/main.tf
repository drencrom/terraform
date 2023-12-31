terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "keystone_machines" {
  count  = var.placement.keystone == null ? var.units.keystone : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "keystone", count.index)
  constraints = "mem=1G"
}

resource "juju_application" "keystone" {
    model = var.model
    name = "keystone"
    charm {
        name = "keystone"
        channel = var.channel.openstack
        series = var.series
    }

    units = var.units.keystone
    placement = var.placement.keystone == null ? join(",", [for machine in juju_machine.keystone_machines : split(":", machine.id)[1]]) : var.placement.keystone
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_application" "keystone_mysql_router" {
    model = var.model
    name = "keystone-mysql-router"
    charm {
        name = "mysql-router"
        channel = var.channel.mysql
        series = var.series
    }

    units = 0 # Subordinate charms must have 0 units
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_integration" "keystone_mysql_router_db_router" {
    model = var.model
    application {
        name = juju_application.keystone_mysql_router.name
        endpoint = "db-router"
    }

    application {
        name = var.relation_names.mysql_innodb_cluster
        endpoint = "db-router"
    }
}

resource "juju_integration" "keystone_mysql_router_shared_db" {
    model = var.model
    application {
        name = juju_application.keystone_mysql_router.name
        endpoint = "shared-db"
    }

    application {
        name = juju_application.keystone.name
        endpoint = "shared-db"
    }
}

resource "juju_integration" "keystone_vault_certificates" {
    count = var.relation_names.vault == null ? 0 : 1
    model = var.model
    application {
        name = juju_application.keystone.name
        endpoint = "certificates"
    }

    application {
        name = var.relation_names.vault
        endpoint = "certificates"
    }
}
