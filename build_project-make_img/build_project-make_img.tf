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

variable "img" {
  type    = string
  default = "fd8iqikoo07s23bhh1vj"
}

resource "yandex_compute_instance" "builder" {
  name = "builder"
  boot_disk {
    initialize_params {
      image_id = var.img
      size     = 20
    }
  }

  resources {
    cores  = 2
    memory = 2
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

  network_interface {
    subnet_id = "e9b7m8esv1qpccpq4793"
    nat       = true
  }

  provisioner "local-exec" {
    command = "sleep 45"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_ed25519")
    host        = self.network_interface[0].nat_ip_address
    timeout     = "3m"
  }

  provisioner "file" {
    source      = "/root/.ssh/key.json"
    destination = "/tmp/key.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y maven docker.io",
      "sudo systemctl start docker",
      "curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | sudo bash -s -- -i /usr/local",
      "export PATH=$PATH:/usr/local/bin",
      #"yc --version"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yc config set service-account-key /tmp/key.json",
      "sudo yc container registry configure-docker",
      "sudo yc iam create-token | docker login --username iam --password-stdin cr.yandex",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/wipefree/warhello.git /tmp/prj",
      "cd /tmp/prj",
      "sudo mvn package -DskipTests"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/prj",
      "sudo docker build -f Dockerfile.builder -t cr.yandex/crpirf1t243rd4chrqfd/hello:latest .",
      "sudo docker push cr.yandex/crpirf1t243rd4chrqfd/hello:latest"
    ]
  }

}
