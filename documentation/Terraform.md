# Terraform

## Install on Ubuntu

To install Terraform on Ubuntu, run the following commands.

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform
```

## Initialize Terraform

To use Terraform, initialize it once in a project's folder to install dependencies and set up the backend to store the terraform state.

```
terraform init
```

## Format the code

To rewrite Terraform configuration files to a canonical format and style, run:

```
terraform fmt
```

## Validate the infrastructure

To validate that the infrastructure's Terraform code is syntactically valid and internally consistent, regardless of any provided variables or existing state, run:

```
terraform validate
```

## Deploy the infrastructure

To deploy an infrastructure with Terraform, run the following command.

```
terraform apply
```

If you need to include variables to your infrastructure, include them in the *terraform/variables/variables.tfvars* and/or *terraform/variables/secrets.tfvars* and use the *-var-file* flag to apply the infrastructure.

```
terraform apply -var-file=../variables/secrets.tfvars -var-file=../variables/variables.tfvars
```

The *-auto-approve* flag can also be used to avoid having to manually approve the deployment of the infrastructure.

```
terraform apply -var-file=../variables/secrets.tfvars -var-file=../variables/variables.tfvars -auto-approve
```

Similarly, to destroy the deployed infrastucture, replace the *apply* keyword in the commands above with the *destroy* keyword, as shown below.

```
terraform destroy -var-file=../variables/secrets.tfvars -var-file=../variables/variables.tfvars -auto-approve
```

## Plan the infrastructure

In case you only need to plan an infrastructure and not immediately deploy it, you can run:

```
terraform plan
```

Similarly, if you need to include variables to your infrastructure, run:

```
terraform plan -var-file=../variables/secrets.tfvars -var-file=../variables/variables.tfvars
```

To export the plan to an output file, include the *-out* flag to the command and specify the filename.

```
terraform plan -var-file=../variables/secrets.tfvars -var-file=../variables/variables.tfvars -out=tfplan
```

To apply the saved plan, just run:

```
terraform apply tfplan
```