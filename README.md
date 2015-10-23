## Mesos Cluster

## Requirements

* terraform

## To get started

```bash
git clone https://github.com/xjdr/mesos-cluster-terraform.git
cd mesos-cluster-terraform
cp terraform.tfvars{.example,}
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```
terraform get # will download modules
terraform plan # will show you the changes to be made in EC2
terraform apply # will make changes in EC2
```
