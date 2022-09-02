/*
module "jenkins" {
  # https://github.com/terraform-google-modules/terraform-google-jenkins
  source = "terraform-google-modules/terraform-google-jenkins"
  version = "1.2.0"

  create_firewall_rules = true
  jenkins_initial_password = "*MY_PASSWORD*"
  jenkins_instance_access_cidrs = ["0.0.0.0/0"]
  jenkins_instance_machine_type = "f1-micro"
  jenkins_workers_machine_type = "f1-micro"
  jenkins_instance_name = "jenkins-gcp"
  jenkins_instance_subnetwork = "us-east1"
}
*/
module "jenkins" {
  source  = "terraform-google-modules/jenkins/google"
  version = "1.2.0"

  project_id                             = "scientific-crow-353414"
  jenkins_workers_project_id             = "scientific-crow-353414"
  region                                 = "us-east1"
  jenkins_instance_zone                  = "us-east1-c"
  jenkins_instance_network               = "default"
  jenkins_workers_network                = "default"
  jenkins_workers_region                 = "us-east1"
  jenkins_instance_subnetwork            = "default"
  jenkins_boot_disk_source_image         = "bitnami-jenkins-2-346-3-1-r01-linux-debian-11-x86-64-nami"
  jenkins_boot_disk_source_image_project = "bitnami-launchpad"
}