terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "dashboard_machines" {
  count  = var.placement.dashboard == null ? var.units.dashboard : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "dashboard", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "openstack_dashboard" {
    model = var.model
    name = "openstack-dashboard"
    charm {
        name = "openstack-dashboard"
        channel = var.channel.openstack
        series = var.series
    }

    units = var.units.dashboard
    placement = var.placement.dashboard == null ? join(",", [for machine in juju_machine.dashboard_machines : split(":", machine.id)[1]]) : var.placement.dashboard
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_application" "openstack_dashboard_mysql_router" {
    model = var.model
    name = "dashboard-mysql-router"
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

resource "juju_integration" "dashboard_mysql_router_db_router" {
    model = var.model
    application {
        name = juju_application.openstack_dashboard_mysql_router.name
        endpoint = "db-router"
    }

    application {
        name = var.relation_names.mysql_innodb_cluster
        endpoint = "db-router"
    }
}

resource "juju_integration" "dashboard_mysql_router_shared_db" {
    model = var.model
    application {
        name = juju_application.openstack_dashboard_mysql_router.name
        endpoint = "shared-db"
    }

    application {
        name = juju_application.openstack_dashboard.name
        endpoint = "shared-db"
    }
}

resource "juju_integration" "openstack_dashboard_keystone" {
    model = var.model
    application {
        name = juju_application.openstack_dashboard.name
        endpoint = "identity-service"
    }

    application {
        name = var.relation_names.keystone
        endpoint = "identity-service"
    }
}

resource "juju_integration" "openstack_dashboard_vault" {
    count = var.relation_names.vault == null ? 0 : 1
    model = var.model
    application {
        name = juju_application.openstack_dashboard.name
        endpoint = "certificates"
    }

    application {
        name = var.relation_names.vault
        endpoint = "certificates"
    }
}

