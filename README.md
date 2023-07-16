# Terraform Juju OpenStack Testing
This repository contains a Terraform plan that deploys OpenStack using the Terraform Juju provider.

## How I use this plan
First configure the desired OpenStack installation state by editing the `config.tf` file.
Then run:
  * `terraform init`
    * Downloads juju provider and other required modules (only once)
  * `terraform apply -parallelism=1`
    * Shows a plan and executes if confirmed. Need to reduce parallelism (10 by default) or juju gets choked and terraform timeouts. Can be re-run after modifying the configuration file
  * `terraform apply -parallelism=1 -destroy`
    * Destroys the created resources. Fails if changes are made manually outside of terraform (eg. removing units)
