resource "google_compute_instance" "nginx" {
    for_each = var.config.cloud.workload

    machine_type = each.value.machine_typename = "nginx-${each.key}"
    zone = "${each.value.region}-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-12"
        }
    }

    network_interface {
        network = "default"
        access_config {}
    }

    tags = ["public"]

    metadata_startup_script = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y nginx
        echo " <!DOCTYOE html> <html lang="fr"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=dev....">"

}