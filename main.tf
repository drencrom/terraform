terraform {
  required_providers {
    juju = {
      version = "~> 0.6.0"
      source  = "juju/juju"
    }
  }
}

provider "juju" {
}

resource "juju_model" "ovb" {
  name = local.model.name

  cloud {
    name   = local.model.cloud.name
    region = local.model.cloud.region
  }

}

module "nova" {
  source  = "./nova"
  model   = juju_model.ovb.name
  channel = local.openstack.channel
  series  = local.series
  mysql = {
    channel = local.mysql.channel
  }
  config    = local.nova.config
  units     = local.nova.units
  placement = local.nova.placement
  relation_names = {
    keystone             = module.keystone.application_names.keystone
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
    neutron_api          = module.neutron_ovs.application_names.neutron_api
    rabbitmq             = module.rabbitmq.application_names.rabbitmq
    vault                = local.vault.enabled ? module.vault[0].application_names.vault : null 
  }
}

module "ceph_cluster" {
  count = local.ceph.enabled ? 1 : 0
  source  = "./ceph"
  model   = juju_model.ovb.name
  channel = local.ceph.channel
  series  = local.series
  config  = local.ceph.config
  units = {
    osds = 3
    mons = 1
    rgw  = 1
  }
  placement = {
    osds = local.ceph.placement.osds
    mons = local.ceph.placement.mons
    rgw  = local.ceph.placement.rgw
  }
  relation_names = {
    nova   = module.nova.application_names.compute
    glance = module.glance.application_names.glance
  }
}

module "vault" {
  count = local.vault.enabled ? 1 : 0
  source  = "./vault"
  model   = juju_model.ovb.name
  channel = local.vault.channel
  series  = local.series
  mysql = {
    channel = local.mysql.channel
  }
  config = {
    vault = local.vault.config
  }
  units = {
    vault = local.vault.units
  }
  placement = {
    vault = local.vault.placement
  }
  relation_names = {
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
  }
}

module "neutron_ovs" {
  source = "./neutron-ovs"
  model  = juju_model.ovb.name
  channel = {
    mysql     = local.mysql.channel
    openstack = local.openstack.channel
  }
  series = local.series
  config = {
    neutron_api = local.neutron.api.config
    neutron_gateway = local.neutron.gateway.config
    neutron_openvswitch = local.neutron.openvswitch.config
  }
  units = {
    neutron_api = local.neutron.api.units
    neutron_gateway = local.neutron.gateway.units
  }
  placement = {
    neutron_api = local.neutron.api.placement
    neutron_gateway = local.neutron.gateway.placement
  }
  relation_names = {
    keystone             = module.keystone.application_names.keystone
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
    nova_compute         = module.nova.application_names.compute
    rabbitmq             = module.rabbitmq.application_names.rabbitmq
    vault                = local.vault.enabled ? module.vault[0].application_names.vault : null
    nova_cloud_controller = module.nova.application_names.cloud_controller
  }
}

module "keystone" {
  source = "./keystone"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
    mysql     = local.mysql.channel
  }
  series = local.series
  units = {
    keystone = local.keystone.units
  }
  placement = {
    keystone = local.keystone.placement
  }
  relation_names = {
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
    vault                = local.vault.enabled ? module.vault[0].application_names.vault : null
  }
}

module "rabbitmq" {
  source = "./rabbitmq"
  model = juju_model.ovb.name
  channel = local.rabbitmq.channel
  units = local.rabbitmq.units
  placement = local.rabbitmq.placement
  series = local.series
}

module "placement" {
  source = "./placement"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
    mysql     = local.mysql.channel
  }
  series = local.series
  units = {
    placement = local.placement.units
  }
  placement = {
    placement = local.placement.placement
  }
  relation_names = {
    keystone              = module.keystone.application_names.keystone
    mysql_innodb_cluster  = module.mysql.application_names.mysql_innodb_cluster
    nova_cloud_controller = module.nova.application_names.cloud_controller
    vault                 = local.vault.enabled ? module.vault[0].application_names.vault : null
  }
}

module "glance" {
  source = "./glance"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
    mysql     = local.mysql.channel
  }
  series = local.series
  units = {
    glance = local.glance.units
  }
  placement = {
    glance = local.glance.placement
  }
  relation_names = {
    keystone              = module.keystone.application_names.keystone
    mysql_innodb_cluster  = module.mysql.application_names.mysql_innodb_cluster
    nova_cloud_controller = module.nova.application_names.cloud_controller
    nova_compute          = module.nova.application_names.compute
    vault                 = local.vault.enabled ? module.vault[0].application_names.vault : null
  }
}

module "cinder" {
  source = "./cinder"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
    mysql     = local.mysql.channel
  }
  series = local.series
  config = {
    cinder = local.cinder.config
  }
  units = {
    cinder = local.cinder.units
  }
  placement = {
    cinder = local.cinder.placement
  }
  relation_names = {
    ceph_mons             = local.ceph.enabled ? module.ceph_cluster[0].application_names.mons : null
    glance                = module.glance.application_names.glance
    keystone              = module.keystone.application_names.keystone
    mysql_innodb_cluster  = module.mysql.application_names.mysql_innodb_cluster
    nova_compute          = module.nova.application_names.compute
    nova_cloud_controller = module.nova.application_names.cloud_controller
    rabbitmq              = module.rabbitmq.application_names.rabbitmq
    vault                 = local.vault.enabled ? module.vault[0].application_names.vault : null
  }
}

module "mysql" {
  source = "./mysql"
  model  = juju_model.ovb.name
  channel = local.mysql.channel
  placement = local.mysql.placement
  units = local.mysql.units
  series = local.series
}

module "dashboard" {
  count = local.dashboard.enabled ? 1 : 0
  source = "./dashboard"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
    mysql     = local.mysql.channel
  }
  series = local.series
  units = {
    dashboard = local.dashboard.units
  }
  placement = {
    dashboard = local.dashboard.placement
  }
  relation_names = {
    keystone             = module.keystone.application_names.keystone
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
    vault                = local.vault.enabled ? module.vault[0].application_names.vault : null
  }
}

module "designate" {
  count = local.designate.enabled ? 1 : 0
  source = "./designate"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
    memcached = local.memcached.channel
    mysql     = local.mysql.channel
  }
  series = local.series
  config = {
    designate = local.designate.config
  }
  units = {
    bind      = local.designate.units.bind
    designate = local.designate.units.designate
    memcached = local.memcached.units
  }
  placement = {
    bind      = local.designate.placement.bind
    designate = local.designate.placement.designate
    memcached = local.memcached.placement
  }
  relation_names = {
    keystone             = module.keystone.application_names.keystone
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
    neutron_api          = module.neutron_ovs.application_names.neutron_api
    rabbitmq             = module.rabbitmq.application_names.rabbitmq
  }
}

module "manila" {
  count = local.manila.enabled ? 1 : 0
  source = "./manila"
  model  = juju_model.ovb.name
  channel = {
    openstack = local.openstack.channel
  }
  series = local.series
  config = {
    manila         = local.manila.config
    manila_generic = local.manila.generic.config
  }
  units = {
    manila = local.manila.units
  }
  placement = {
    manila = local.manila.placement
  }
  relation_names = {
    keystone             = module.keystone.application_names.keystone
    mysql_innodb_cluster = module.mysql.application_names.mysql_innodb_cluster
    rabbitmq             = module.rabbitmq.application_names.rabbitmq
  }
}
