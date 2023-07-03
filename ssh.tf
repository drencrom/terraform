resource "juju_ssh_key" "model-key" {
  model   = local.model.name
  payload = file("~/.ssh/id_rsa.pub")
}
