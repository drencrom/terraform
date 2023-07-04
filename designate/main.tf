terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "designate_machines" {
  count  = var.placement.designate == null ? var.units.designate : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "designate", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "designate" {
    model = var.model
    name = "designate"
    charm {
        name = "designate"
        channel = var.channel.openstack
        series = var.series
    }
    config = var.config.designate
    units = var.units.designate
    placement = var.placement.designate == null ? join(",", [for machine in juju_machine.designate_machines : split(":", machine.id)[1]]) : var.placement.designate
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_machine" "designate_bind_machines" {
  count  = var.placement.bind == null ? var.units.bind : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "designate_bind", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "designate_bind" {
    model = var.model
    name = "designate-bind"
    charm {
        name = "designate-bind"
        channel = var.channel.openstack
        series = var.series
    }
    units = var.units.bind
    placement = var.placement.bind == null ? join(",", [for machine in juju_machine.designate_bind_machines : split(":", machine.id)[1]]) : var.placement.bind
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_integration" "designate_designate_bind" {
    model = var.model
    application {
        name = juju_application.designate.name
    }

    application {
        name = juju_application.designate_bind.name
    }
}

resource "juju_machine" "memcached_machines" {
  count  = var.placement.memcached == null ? var.units.memcached : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "memcached", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "memcached" {
    model = var.model
    name = "memcached"
    charm {
        name = "memcached"
        channel = var.channel.memcached
        series = var.series
    }
    units = var.units.memcached
    placement = var.placement.memcached == null ? join(",", [for machine in juju_machine.memcached_machines : split(":", machine.id)[1]]) : var.placement.memcached
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_integration" "designate_memcached" {
    model = var.model
    application {
        name = juju_application.designate.name
    }

    application {
        name = juju_application.memcached.name
    }
}

resource "juju_integration" "designate_mysql" {
    model = var.model
    application {
        name = juju_application.designate.name
    }

    application {
        name = var.relation_names.mysql_innodb_cluster
    }
}

resource "juju_integration" "designate_rabbitmq" {
    model = var.model
    application {
        name = juju_application.designate.name
    }

    application {
        name = var.relation_names.rabbitmq
    }
}

resource "juju_integration" "designate_keystone" {
    model = var.model
    application {
        name = juju_application.designate.name
    }

    application {
        name = var.relation_names.keystone
    }
}

resource "juju_integration" "designate_neutron_api" {
    model = var.model
    application {
        name = juju_application.designate.name
    }

    application {
        name = var.relation_names.neutron_api
    }
}
