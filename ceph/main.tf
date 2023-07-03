terraform {
    required_providers {
        juju = {
            version = "~> 0.6.0"
            source = "juju/juju"
        }
    }
}

resource "juju_machine" "ceph_osd_machines" {
  count  = var.placement.osds == null ? var.units.osds : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "ceph_osd", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "ceph_osds" {
    model = var.model
    charm {
        name = "ceph-osd"
        channel = var.channel
        series = var.series
    }
    config = var.config.osds
    units = var.units.osds
    placement = var.placement.osds == null ? join(",", [for machine in juju_machine.ceph_osd_machines : split(":", machine.id)[1]]) : var.placement.osds
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_machine" "ceph_mon_machines" {
  count  = var.placement.mons == null ? var.units.mons : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "ceph_mon", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "ceph_mon" {
    model = var.model
    name = "ceph-mon"
    charm {
        name = "ceph-mon"
        channel = var.channel
        series = var.series
    }
    config = var.config.mons
    units = var.units.mons
    placement = var.placement.mons == null ? join(",", [for machine in juju_machine.ceph_mon_machines : split(":", machine.id)[1]]) : var.placement.mons
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_machine" "ceph_rgw_machines" {
  count  = var.placement.rgw == null ? var.units.rgw : 0
  model  = var.model
  series = var.series
  name   = format("%s%s", "ceph_rgw", count.index)
  constraints = "mem=2G"
}

resource "juju_application" "ceph_radosgw" {
    model = var.model
    name = "ceph-radosgw"
    charm {
        name = "ceph-radosgw"
        channel = var.channel
        series = var.series
    }

    units = var.units.rgw
    placement = var.placement.rgw == null ? join(",", [for machine in juju_machine.ceph_rgw_machines : split(":", machine.id)[1]]) : var.placement.rgw
    lifecycle {
        ignore_changes = [ placement, ]
    }
}

resource "juju_integration" "ceph_mon_ceph_osd" {
    model = var.model
    application {
        name = juju_application.ceph_mon.name
        endpoint = "osd"
    }

    application {
        name = juju_application.ceph_osds.name
        endpoint = "mon"
    }
}

resource "juju_integration" "ceph_mon_nova_compute" {
    model = var.model
    application {
        name = juju_application.ceph_mon.name
        endpoint = "client"
    }

    application {
        name = var.relation_names.nova
        endpoint = "ceph"
    }
}

resource "juju_integration" "ceph_mon_glance" {
    model = var.model
    application {
        name = juju_application.ceph_mon.name
        endpoint = "client"
    }

    application {
        name = var.relation_names.glance
        endpoint = "ceph"
    }
}

resource "juju_integration" "ceph_radosgw_ceph_mon" {
    model = var.model
    application {
        name = juju_application.ceph_radosgw.name
        endpoint = "mon"
    }

    application {
        name = juju_application.ceph_mon.name
        endpoint = "radosgw"
    }
}
