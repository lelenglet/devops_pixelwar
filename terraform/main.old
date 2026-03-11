
# -----------------------------------------------------------------------------
# Config TERRAFORM
terraform {   

  required_providers {     
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.4.0"
    }
    talos = {       
      source = "siderolabs/talos"        
      version = "0.10.1"
    }   
  }
} 


# -----------------------------------------------------------------------------
# Config locale
locals {   
  cluster_name        = "tp5"   
  kubernetes_version  = "1.34.5"
  flavor_controlplane = "medium-2c-2gb"
  flavor_worker       = "small-1c-1gb"
}

# -----------------------------------------------------------------------------
# Security Group

## Communications internes 
resource "openstack_networking_secgroup_v2" "cluster" {
  name        = "${local.cluster_name}-cluster"
  description = "${local.cluster_name} - cluster communications"
}

resource "openstack_networking_secgroup_rule_v2" "cluster_ingress_ipv4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id = openstack_networking_secgroup_v2.cluster.id
  security_group_id = openstack_networking_secgroup_v2.cluster.id
}

resource "openstack_networking_secgroup_rule_v2" "cluster_ingress_ipv6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  remote_group_id = openstack_networking_secgroup_v2.cluster.id
  security_group_id = openstack_networking_secgroup_v2.cluster.id
}

resource "openstack_networking_secgroup_rule_v2" "cluster_ingress_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cluster.id
}

## Controlplane endpoint access
resource "openstack_networking_secgroup_v2" "controlplane" {
  name                 = "${local.cluster_name}-controlplane"
  description          = "${local.cluster_name} - access to controlplane endpoints"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "controlplane_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/32"
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
}

resource "openstack_networking_secgroup_rule_v2" "controlplane_ingress" {
  for_each          = toset(["50000", "6443", "80", "443"])
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = each.key 
  port_range_max    = each.key 
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
}

# -----------------------------------------------------------------------------
# Ressources Openstack

data "openstack_networking_network_v2" "private" {
  #name = local.network_name
  external = false
}

data "openstack_images_image_v2" "talos" {
  name_regex  = "talos.*"
  most_recent = true
}

resource "openstack_networking_port_v2" "controlplane" {
  name           = "${local.cluster_name}-port-controlplane"
  network_id     = data.openstack_networking_network_v2.private.id
  admin_state_up = "true"
  
  security_group_ids = [
    openstack_networking_secgroup_v2.cluster.id,
    openstack_networking_secgroup_v2.controlplane.id
  ]
}

resource "openstack_networking_floatingip_v2" "endpoint" {
  pool = "provider_network"
}

resource "openstack_networking_floatingip_associate_v2" "endpoint" {
  floating_ip = openstack_networking_floatingip_v2.endpoint.address
  port_id = openstack_networking_port_v2.controlplane.id 
}

resource "openstack_compute_instance_v2" "controlplane" {   
  name            = "${local.cluster_name}-controlplane"   
  image_id        = data.openstack_images_image_v2.talos.id
  flavor_name     = local.flavor_controlplane 
  user_data       = data.talos_machine_configuration.controlplane.machine_configuration   

  network {    
    port = openstack_networking_port_v2.controlplane.id
  }     

  lifecycle {     
    ignore_changes = [ user_data, image_id ]   
  } 
}

resource "openstack_compute_instance_v2" "worker" {   
  count           = 2 
  name            = "${local.cluster_name}-worker-${count.index}"   
  image_id        = data.openstack_images_image_v2.talos.id  
  flavor_name     = local.flavor_worker 
  user_data       = data.talos_machine_configuration.worker.machine_configuration   
  security_groups = [ 
    openstack_networking_secgroup_v2.cluster.name,     
  ]

  network {    
    name = data.openstack_networking_network_v2.private.name
  }     
}

# -----------------------------------------------------------------------------
# Ressources Talos

locals {
  zzcluster_registry = yamlencode({
    machine = {
      registries = {
        mirrors = {
          "zzcluster.io" = {
            endpoints = [
              "https://10.20.22.17:5000"
            ]
          }
        },
      },
      files = [
        { 
          permissions = 0644,
          path = "/etc/ssl/certs/ca-certificates",
          op = "append",
          content = <<-EOF
            -----BEGIN CERTIFICATE-----
            MIIFBjCCAu6gAwIBAgIUIrdA6Huw7D70wfz++4Pt9556Vf0wDQYJKoZIhvcNAQEL
            BQAwGzEZMBcGA1UEAwwQVUNBIFpaQ2x1c3RlciBDQTAeFw0yNjAzMDcxNDU1MTha
            Fw0zNjAzMDQxNDU1MThaMBsxGTAXBgNVBAMMEFVDQSBaWkNsdXN0ZXIgQ0EwggIi
            MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDiKSeaceXZryuNO4ovJoFTTmXz
            QkV9MZvLWzvT9AoFeqzKkixHteKpHcE4BA5pevqaGFfTJiBJuVJ3stL3bh9vlrYW
            7bUn6ndm26CbrytP9HX3UMzZn6pesFuyCD9AvX+I8VOln70TtjeH5n4mefPdbway
            l+nkG2fQ4rWfdseTnGkA0F4XcbtmrfrsUR74CE2q5Ofagv9FbINSZGaKrbM83HZT
            TXdCGhy9PiWwHNR+6yrLl/Mt4JLtHRkkU/4PK4rtfvoJi4tjNGUXgjKY+E4ehY1b
            tB1ePzTZJl8jjCgxiHvd/m32bBNUe8ApbSmXXAt07nJc4ok0BZ1i2fjRWW7VFZ7J
            yb7LXKGtyMf6suEHorWT652ATupEDuFagz3G6qQB2mkU7ssbnUUEBbG40TJS3EH5
            k/dihe4eo1mHiobHsQQ/cur+bIB167eKTDdvlaE9YOhvj9DRiuj44Rnlr46y2a/0
            +2XCxYAxbEpE5at/qYrr6k4VCRUQDLn4ZzfebKKu+IaZvIyGEX6V5iIHBzJ3IzBg
            xFlKxuvEr+Dzgrh4X1OLyLFaFVpJaPBRRCyMkUpBC1KXj64+Uguok0fV5wB8UYbV
            8gp9xeWdqxLVlceeI4mGjPGsTtr2KsX6XCS+DsR7XRSNsvZG2HwoQZoKN4Uo/UVo
            9fPWxN636ks5PcuOiwIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAgQwDwYDVR0TAQH/
            BAUwAwEB/zAdBgNVHQ4EFgQU2D2Twr8a90ihXc71tnip+0v5tFMwDQYJKoZIhvcN
            AQELBQADggIBAK3oQlzysPfwADUr3r5Jvu/HJzrD0ww1qmF4maDubtglcBuca8be
            WD3VNkGmbX0AsXvc6HgeBdBFi1UrIXpdcECL67c8TKp/DTnzGyMdzaQfKLBbdjO7
            Hjl9NsB4dgerNc7nI2b69DMKfWzWH8UFo5/wAQiViIn8bPyxOpiI3MHxO7cNxVWI
            IzMOiPHMWedIsVhpCIvpLMxLj+aSTtaz6YWHbcYKncHNI2EdEiHQgnMGyrAYu66q
            loU0UHCg2HI/qFvBAIltGyw5chyXiVyfUR3ioJqtUjDplWRLqEx3sg8EPZuBEzZi
            p2pyDTB3tIes8x79udwK/aaOIKHaTW37Zz3X2bqcHnVANxAS//AGfvqg7EhFBIdf
            vObiAX9/1yWrGN1wX+UbXMhFh2oGhOodTGaUGL1Eqj2xOfNxcTmZnKivNpEheGf2
            O9C+L2bdbSYMHAO9NIFOTnDh90R4NW5siNbw8afViw+SKrm3dUXJ1wEG8CJckD5E
            Xed/NnM3WXKf4QyZBQ2VTWvziFvRRCDNNFJQifJW7BVIn2xxsccfNpm9VB4vQmMx
            /6aWGw+YI/CxN7vy3ZwJvZMVpmXbeD0uVs7XDKugloaVPuoLFugGWttOipWyKZKB
            5uTYvtGjDTQRidFAMxOgcOpjQ3KjUxJJcFcmTB0MztAsCAJd72hTvYiz
            -----END CERTIFICATE-----
          EOF
        }
      ]
    }
  })
}


resource "talos_machine_secrets" "secrets" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${openstack_networking_floatingip_v2.endpoint.address}:6443"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  kubernetes_version = local.kubernetes_version
  config_patches = [
    local.zzcluster_registry,
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = local.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = "https://${openstack_networking_floatingip_v2.endpoint.address}:6443"
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  kubernetes_version = local.kubernetes_version
  config_patches = [
    local.zzcluster_registry,
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoint             = "https://${openstack_networking_floatingip_v2.endpoint.address}:50000"
  node                 = openstack_networking_floatingip_v2.endpoint.address
  depends_on           = [
    openstack_networking_floatingip_associate_v2.endpoint,
    openstack_compute_instance_v2.controlplane 
  ]
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = openstack_networking_floatingip_v2.endpoint.address
  depends_on           = [
    talos_machine_bootstrap.bootstrap
  ]
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoints            = [openstack_networking_floatingip_v2.endpoint.address]
  nodes                = [openstack_networking_floatingip_v2.endpoint.address]
}

# -----------------------------------------------------------------------------
# Outputs

output "endpoint" {
  value = openstack_networking_floatingip_v2.endpoint.address
}

output "kube_config" {
  value = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true 
}

output "talos_config" {
  value = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true 
}
