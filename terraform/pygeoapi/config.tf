resource "null_resource" "write_config" {
  count = var.config_output_location == "" ? 0 : 1

  triggers = {
    always_run = "${timestamp()}"
  }
  
  provisioner "local-exec" {
    command = <<EOF
    cat <<SECRETS >${var.config_output_location}
app_url: ${azurerm_linux_web_app.this.default_hostname}
postgres_dbname: ${var.postgres_db_name}
postgres_host: ${var.postgres_db_host}
postgres_reader_password: '${var.postgres_db_reader_password}'
postgres_reader_username: ${var.postgres_db_reader_username}
pygeoapi_input_port: ${var.pygeoapi_input_port}
SECRETS
    chmod 0600 ${var.config_output_location}
    EOF
  }
}
