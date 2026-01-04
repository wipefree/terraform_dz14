terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

variable "vms" {
  description = "Configuration of new VM"
  type = map(object({
    cores  = number
    memory = number
    disk   = number
  }))
  # List of new VM
  default = {
    web = { cores = 2, memory = 2, disk = 20 },
    #db  = { cores = 2, memory = 2, disk = 20 },
    #app = { cores = 2, memory = 4, disk = 20 }
  }
}

variable "img" {
  type = string
  default = "fd8iqikoo07s23bhh1vj"
}

resource "yandex_compute_instance" "vm" {

  for_each = var.vms

    name = "${each.key}-server"
    boot_disk {
      initialize_params {
        image_id = var.img
        size     = each.value.disk
      }
    }

    resources {
      cores  = each.value.cores
      memory = each.value.memory
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    }

    network_interface {
      subnet_id = "e9b7m8esv1qpccpq4793"
      nat       = true
    }

}
