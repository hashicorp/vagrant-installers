variable "mac_host" {}
variable "mac_user" {}
variable "mac_password" {}

resource "null_resource" "mac" {
    connection {
        host = "${var.mac_host}"
        user = "${var.mac_user}"
        password = "${var.mac_password}"
        script_path = "/Users/${var.mac_user}/tf_%RAND%.sh"
    }

    provisioner "local-exec" {
        command = "mkdir -p ${path.module}/output"
    }

    provisioner "remote-exec" {
        script = "${path.module}/scripts/mac.sh"
    }

    provisioner "local-exec" {
        command = "${path.module}/scripts/scp.expect ${var.mac_user} ${var.mac_host} '${var.mac_password}' /tmp/substrate_darwin_x86_64.zip ${path.module}/output/substrate_darwin_x86_64.zip"
    }
}
