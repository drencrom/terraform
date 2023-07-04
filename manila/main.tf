terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "manila_machines" {
  count  = var.placement.manila == null ? var.units.manila : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "manila", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "manila" {
    model = var.model
    name = "manila"
    charm {
        name = "manila"
        channel = var.channel.openstack
        series = var.series
    }
    config = var.config.manila
    units = var.units.manila
    placement = var.placement.manila == null ? join(",", [for machine in juju_machine.manila_machines : split(":", machine.id)[1]]) : var.placement.manila
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_application" "manila_generic" {
    model = var.model
    name = "manila-generic"
    charm {
        name = "manila-generic"
        channel = var.channel.openstack
        series = var.series
    }
    config = var.config.manila_generic
    units = 0 # Subordinate charms must have 0 units
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_integration" "manila_mysql" {
    model = var.model
    application {
        name = juju_application.manila.name
    }

    application {
        name = var.relation_names.mysql_innodb_cluster
    }
}

resource "juju_integration" "manila_rabbitmq" {
    model = var.model
    application {
        name = juju_application.manila.name
    }

    application {
        name = var.relation_names.rabbitmq
    }
}

resource "juju_integration" "manila_keystone" {
    model = var.model
    application {
        name = juju_application.manila.name
    }
    
    application {
        name = var.relation_names.keystone
    }
}

resource "juju_integration" "manila_manila_generic" {
    model = var.model
    application {
        name = juju_application.manila.name
        endpoint = "manila-plugin"
    }

    application {
        name = juju_application.manila_generic.name
        endpoint = "manila-plugin"
    }
}
