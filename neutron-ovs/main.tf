terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_application" "neutron_api" {
    model = var.model
    name = "neutron-api"
    charm {
        name = "neutron-api"
        channel = var.channel.openstack
        series = var.series
    }

    config = var.config.neutron_api

    units = var.units.neutron_api
    placement = var.placement.neutron_api
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_application" "neutron_api_mysql_router" {
    model = var.model
    name = "neutron-api-mysql-router"
    charm {
        name = "mysql-router"
        channel = var.channel.mysql
        series = var.series
    }

    units = 0
    #placement = juju_application.neutron_api.placement
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_application" "neutron_gateway" {
    model = var.model
    name = "neutron-gateway"
    charm {
        name = "neutron-gateway"
        channel = var.channel.openstack
        series = var.series
    }

    config = var.config.neutron_gateway

    units = var.units.neutron_gateway
    placement = var.placement.neutron_gateway
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_application" "neutron_openvswitch" {
    model = var.model
    name = "neutron-openvswitch"
    charm {
        name = "neutron-openvswitch"
        channel = var.channel.openstack
        series = var.series
    }

    config = var.config.neutron_openvswitch

    units = 0
    #placement = var.placement.neutron_openvswitch
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_integration" "neutron_api_mysql_router_db_router" {
    model = var.model
    application {
        name = juju_application.neutron_api_mysql_router.name
        endpoint = "db-router"
    }

    application {
        name = var.relation_names.mysql_innodb_cluster
        endpoint = "db-router"
    }
}

resource "juju_integration" "neutron_api_mysql_router_shared_db" {
    model = var.model
    application {
        name = juju_application.neutron_api_mysql_router.name
        endpoint = "shared-db"
    }

    application {
        name = juju_application.neutron_api.name
        endpoint = "shared-db"
    }
}

resource "juju_integration" "neutron_api_vault" {
    count = var.relation_names.vault == null ? 0 : 1
    model = var.model
    application {
        name = juju_application.neutron_api.name
        endpoint = "certificates"
    }

    application {
        name = var.relation_names.vault
        endpoint = "certificates"
    }
}

resource "juju_integration" "rabbitmq_neutron_api" {
    model = var.model
    application {
        name = var.relation_names.rabbitmq
        endpoint = "amqp"
    }

    application {
        name = juju_application.neutron_api.name
        endpoint = "amqp"
    }
}

resource "juju_integration" "keystone_neutron_api" {
    model = var.model
    application {
        name = var.relation_names.keystone
        endpoint = "identity-service"
    }

    application {
        name = juju_application.neutron_api.name
        endpoint = "identity-service"
    }
}

resource "juju_integration" "neutron_gateway_neutron_api" {
    model = var.model
    application {
        name = juju_application.neutron_gateway.name
        endpoint = "neutron-plugin-api"
    }

    application {
        name = juju_application.neutron_api.name
        endpoint = "neutron-plugin-api"
    }
}

resource "juju_integration" "rabbitmq_neutron_gateway" {
    model = var.model
    application {
        name = var.relation_names.rabbitmq
        endpoint = "amqp"
    }

    application {
        name = juju_application.neutron_gateway.name
        endpoint = "amqp"
    }
}

resource "juju_integration" "nova_cloud_controller_neutron_gateway" {
    model = var.model
    application {
        name = var.relation_names.nova_cloud_controller
        endpoint = "quantum-network-service"
    }

    application {
        name = juju_application.neutron_gateway.name
        endpoint = "quantum-network-service"
    }
}

resource "juju_integration" "neutron_openvswitch_neutron_api" {
    model = var.model
    application {
        name = juju_application.neutron_openvswitch.name
        endpoint = "neutron-plugin-api"
    }

    application {
        name = juju_application.neutron_api.name
        endpoint = "neutron-plugin-api"
    }
}

resource "juju_integration" "rabbitmq_neutron_openvswitch" {
    model = var.model
    application {
        name = var.relation_names.rabbitmq
        endpoint = "amqp"
    }

    application {
        name = juju_application.neutron_openvswitch.name
        endpoint = "amqp"
    }
}

resource "juju_integration" "nova_compute_neutron_openvswitch" {
    model = var.model
    application {
        name = var.relation_names.nova_compute
        endpoint = "neutron-plugin"
    }

    application {
        name = juju_application.neutron_openvswitch.name
        endpoint = "neutron-plugin"
    }
}
