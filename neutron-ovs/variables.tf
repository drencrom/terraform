variable "model" {
    type = string
}

variable "channel" {
    type = object({
        openstack = string
        mysql = string
    })
}

variable "series" {
    type = string
}

variable "config" {
    type = object({
        neutron_api = map(any)
        neutron_gateway = map(any)
        neutron_openvswitch = map(any)
    })
}

variable "units" {
    type = object({
        neutron_api = number
        neutron_gateway = number
    })
}

variable "placement" {
    type = object({
        neutron_api = string
        neutron_gateway = string
    })
}

variable "relation_names" {
    type = object({
        keystone = string
        mysql_innodb_cluster = string
        nova_compute = string
        rabbitmq = string
        vault = string
	nova_cloud_controller = string
    })
}
