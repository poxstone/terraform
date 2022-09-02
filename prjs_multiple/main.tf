locals {
  org_id = "578431316016"
  prj_prefix = "pox-xyz-"
  prjs = ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69"]
}

resource "google_project" "projects_array" {
  for_each = toset(local.prjs)
  name       = "${local.prj_prefix}-${each.value}"
  project_id = "${local.prj_prefix}-${each.value}"
  org_id     = local.org_id
}

resource "google_project_service" "projects_service" {
  for_each = toset(local.prjs)
  project = "${local.prj_prefix}-${each.value}"
  service = "compute.googleapis.com"
  timeouts {
    create = "30m"
    update = "40m"
  }
  disable_dependent_services = true
  depends_on = [
    google_project.projects_array
  ]
}