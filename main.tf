resource "yandex_vpc_network" "main" {
  name = "freeipa-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "freeipa-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

data "yandex_compute_image" "ubuntu" {
  family = "almalinux-9"
}

resource "yandex_compute_instance" "vm" {
  name        = "freeipa-instance"
  platform_id = "standard-v3"

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file("~/.ssh/id_ed25519.pub")}"
  }

  scheduling_policy {
    preemptible = false
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = self.network_interface[0].nat_ip_address
    private_key = file("~/.ssh/id_ed25519")
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = ["echo 'SSH connection established'"]
  }
}

resource "null_resource" "vm" {
  provisioner "local-exec" {
    command = <<EOF
      ansible-galaxy collection install freeipa.ansible_freeipa
      #ansible-playbook -i inventory.yml provision/playbook.yml
    EOF
    environment = {
      ANSIBLE_HOST_KEY_CHECKING  = "False"
      ANSIBLE_CONFIG             = "${path.module}/ansible.cfg"
    }
  }
  depends_on = [yandex_compute_instance.vm]
}


resource "local_file" "inventory_yml" {
  content = templatefile("inventory_yml.tpl",
    {
      hostname           = "freeipa-instance"
      ssh_user           = var.ssh_user
      freeipa_public_ip  = yandex_compute_instance.vm.network_interface[0].nat_ip_address
    }
  )
  filename = "inventory.yml"
}
