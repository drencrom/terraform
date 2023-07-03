locals {
  series = "focal"
}

locals {
  model = {
    name = "ovb"
    cloud = {
      name   = "stsstack"
      region = "stsstack"
    }
  }
}

locals {
  openstack = {
    channel = "yoga/stable"
    origin  = "cloud:focal-yoga"
  }
}

locals {
  ceph = {
    enabled = false
    channel = "quincy/stable"
    config = {
      osds = {
        osd-devices = "/dev/vdb"
        source      = local.openstack.origin
      }
      mons = {
	monitor-count = 1
	expected-osd-count = 3
        source      = local.openstack.origin
      }
      rgw  = {}
    }
  }
}

locals {
  nova = {
    config = {
      compute = {
        config-flags          = "default_ephemeral_format=ext4"
        enable-live-migration = "true"
        enable-resize         = "true"
        migration-auth-type   = "ssh"
        virt-type             = "qemu"
        openstack-origin = local.openstack.origin
      }
      cloud_controller = {
        network-manager  = "Neutron"
        openstack-origin = local.openstack.origin
      }
    }
    units = {
      compute          = 2
      cloud_controller = 1
    }
    placement = {
      compute          = null #"${local.juju_ids[0]}"
      cloud_controller = null #"${local.juju_ids[1]}"
    }
  }
}

locals {
  mysql = {
    channel = "8.0/stable"
  }
}

locals {
  vault = {
    enabled = false
    channel = "1.7/stable"
    config = {
      totally-unsecure-auto-unlock = "true"
      auto-generate-root-ca-cert   = "true"
    }
    units     = 1
    placement = "${local.juju_ids[2]}"
  }
}

locals {
  neutron = {
    api = {
      config = {
	default-tenant-network-type = "vxlan"
        neutron-security-groups = "true"
        flat-network-providers  = "physnet1"
        openstack-origin        = local.openstack.origin
	enable-ml2-port-security = "true"
	#ssl_ca = "*ssl_ca"
      	#ssl_cert = "*ssl_cert"
      	#ssl_key = "*ssl_key"
      	global-physnet-mtu = "8958"  # maximum available mtu in stsstack
      	path-mtu = "1550"
      	physical-network-mtus = "physnet1:1500"
 	overlay-network-type = "vxlan gre"
      	manage-neutron-plugin-legacy-mode = "true"
      }
      units     = 1
      placement = "${local.juju_ids[3]}"
    }
    gateway = {
      config = {
        bridge-mappings = "physnet1:br-data"
        enable-isolated-metadata = "true"
        openstack-origin        = local.openstack.origin
      }
      units     = 1
      placement = "${local.juju_ids[0]}"
    }
    openvswitch = {
      config = {
        firewall-driver = "openvswitch"
        enable-local-dhcp-and-metadata = "true"
      }
    }
  }
}

locals {
  keystone = {
    units     = 1
    placement = "${local.juju_ids[4]}"
  }
}

locals {
  placement = {
    units     = 1
    placement = "${local.juju_ids[5]}"
  }
}

locals {
  glance = {
    units     = 1
    placement = "${local.juju_ids[6]}"
  }
}

locals {
  rabbitmq = {
    channel = "3.9/stable"
    placement = "${local.juju_ids[1]}"
  }
}

locals {
  cinder = {
    config = {
      block-device       = "None"
      glance-api-version = "2"
      openstack-origin   = "distro"
    }
    units     = 1
    placement = "${local.juju_ids[7]}"
  }
}

