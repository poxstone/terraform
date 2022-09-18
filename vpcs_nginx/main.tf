locals {
    project_id = "scientific-crow-353414"
    project_number = "228562183448"
    region = "us-east1"
    zone = "${local.region}-c"
    vpc_prefix = "vpc"
    vm_prefix = "vm"
    vpc_cant = ["0", "1", "2", "3"]
    vm_cant = slice(local.vpc_cant, 0, length(local.vpc_cant)-1)
    vm_type = "e2-medium"
    vm_image = "debian-cloud/debian-11"
    vm_service_account = "${local.project_number}-compute@developer.gserviceaccount.com"
    metadata_startup_script = "apt-get update -y; apt-get upgrade; apt-get install -y git vim tmux tcpdump nmap nginx docker docker.io containerd runc; systemctl enable nginx; systemctl restart nginx; touch /etc/nginx/sites-available/reverse-proxy.conf;ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf; docker run -itd --restart=always --pull always --net host -e VERSION_DEP=MAIN -p 8080:8080 poxstone/flask_any_response; echo FINALIZADO"
}

module "vpcs" {
  for_each = toset(local.vpc_cant)
  
  source = "terraform-google-modules/network/google"
  version = "~> 4.0"
  project_id  = local.project_id
  network_name = "${local.vpc_prefix}-${each.value}"
  routing_mode = "REGIONAL"
  subnets = [{
      subnet_name     = "${local.vpc_prefix}-${each.value}-${local.region}"
      subnet_ip       = "10.${each.value}.0.0/27"
      subnet_region   = local.region
  }]
  secondary_ranges = {
    subnet-01 = [{
        range_name    = "${local.vpc_prefix}-${each.value}-${local.region}-subnet-${each.value}"
        ip_cidr_range = "10.${each.value}.1.0/27"
    }]
  }
  routes = [{
      name                = "${local.vpc_prefix}-${each.value}-egress-internet"
      description         = "${local.vpc_prefix}-${each.value} route through IGW to access internet"
      destination_range   = "0.0.0.0/0"
      #tags                = "egress-inet"
      next_hop_internet   = "true"
  }]
  firewall_rules = [{
    name                    = "${local.vpc_prefix}-${each.value}-allow-ssh-ingress"
    direction               = "INGRESS"
    ranges                  = ["0.0.0.0/0"]
    allow = [{
      protocol = "all"
      ports    = []
    }]
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}
output "vpcs" {
    value = module.vpcs[0].subnets_names[0]
}

# compute instances
resource "google_compute_instance" "vms" {
  for_each = toset(local.vm_cant)

  name         = "${local.vm_prefix}-${each.value}to${sum([each.value,1])}"
  machine_type = local.vm_type
  zone         = local.zone
  project      = local.project_id
  can_ip_forward = true
  metadata_startup_script = local.metadata_startup_script
  boot_disk {
    initialize_params { image = local.vm_image }
  }
  network_interface {
    #subnetwork = module.vpcs[sum([each.value,0])].subnets_names[0]
    subnetwork = "https://www.googleapis.com/compute/v1/projects/${local.project_id}/regions/${local.region}/subnetworks/${local.vpc_prefix}-${sum([each.value,0])}-${local.region}"
    network_ip = "10.${each.value}.0.2"
    access_config {}
  }
  network_interface {
    #subnetwork = module.vpcs[sum([each.value,1])].subnets_names[0]
    subnetwork = "https://www.googleapis.com/compute/v1/projects/${local.project_id}/regions/${local.region}/subnetworks/${local.vpc_prefix}-${sum([each.value,1])}-${local.region}"
    network_ip = "10.${sum([each.value,1])}.0.3"
    access_config {}
  }
  service_account {
    email  = local.vm_service_account
    scopes = ["cloud-platform"]
  }
   metadata = {
    print = module.vpcs[each.value].subnets_names[0]
  }
  depends_on = [module.vpcs]
}

# instance group
resource "google_compute_instance_group" "vm_group_1" {
  name        = "group-${google_compute_instance.vms[0].name}"
  project      = local.project_id
  zone        = local.zone
  network     = module.vpcs[0].network_id
  instances = [
    google_compute_instance.vms[0].id
  ]
  named_port {
    name = "http-80"
    port = "80"
  }
  named_port {
    name = "http-8080"
    port = "8080"
  }
  named_port {
    name = "http-443"
    port = "443"
  }
  depends_on = [google_compute_instance.vms[0]]
}

#health checks
resource "google_compute_region_health_check" "hc_tcp_ports" {
  for_each           = toset(["80","8080","443","5000"])
  project            = local.project_id
  region             = local.region
  name               = "hc-tcp-region-${each.value}"
  timeout_sec        = 3
  check_interval_sec = 5
  tcp_health_check {
    port = each.value
  }
}

# peering can debloqued comunications

module "peering" {
  source                    = "terraform-google-modules/network/google//modules/network-peering"
  prefix                    = "np"
  local_network             = module.vpcs[1].network_self_link
  peer_network              = module.vpcs[2].network_self_link
  export_peer_custom_routes = true
  depends_on = [module.vpcs]
}