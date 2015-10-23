variable "region" {
  default = "us-west-2"
}

variable "subnet" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = {
    "0" = "us-west-2a"
    "1" = "us-west-2b"
    "2" = "us-west-2c"
  }
}

variable "public_cidr_blocks" {
  default = {
    "0" = "10.0.0.0/24"
    "1" = "10.0.1.0/24"
    "2" = "10.0.2.0/24"
  }
}

variable "private_cidr_blocks" {
  default = {
    "0" = "10.0.10.0/24"
    "1" = "10.0.11.0/24"
    "2" = "10.0.12.0/24"
  }
}

variable "zookeeper_ips" {
  default = {
    "0" = "10.0.10.20"
    "1" = "10.0.11.20"
    "2" = "10.0.12.20"
  }
}

variable "zk_my_id" {
  default = {
    "0" = "1"
    "1" = "2"
    "2" = "3"
  }
}

variable "keypair" {
  default = "xxx"
}

variable "cluster_name" {
  default = "MesosCluster"
}

variable "dockerhub_uri" {
  default = "https://dockerhub.com"
}

variable "dockerhub_auth" {
  default = "xxxx"
}

variable "dockerhub_email" {
  default = "xxxx"
}

variable "whitelist_ips" {
  default = "xxxx"
}

variable "zookeeper_amis" {
  default = {
    us-west-2 = "xxxx"
  }
}

variable "mesos_master_amis" {
  default = {
    us-west-2 = "xxx"
  }
}

variable "mesos_slave_amis" {
  default = {
    us-west-2 = "xxxxx"
  }
}

variable "marathon_amis" {
  default = {
    us-west-2 = "xxxx"
  }
}

variable "marathon_load_balancer_amis" {
  default = {
    us-west-2 = "xxxx"
  }
}

variable "route53_zone_id" {
  default = "xxxxx"
}

variable "route53_zone_fqdn" {
  default = "xxxx"
}

