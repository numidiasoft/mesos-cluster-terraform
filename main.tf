provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "runtime" {
  cidr_block = "${var.subnet}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "Mesos VPC"
  }
}

resource "aws_subnet" "private" {
  count = 3
  vpc_id = "${aws_vpc.runtime.id}"
  availability_zone = "${lookup(var.availability_zones, count.index)}"
  cidr_block = "${lookup(var.private_cidr_blocks, count.index)}"
  map_public_ip_on_launch = false
  tags {
    Name = "Mesos Private ${count.index}"
    Subnet = "Private"
  }
}

resource "aws_subnet" "public" {
  count = 3
  vpc_id = "${aws_vpc.runtime.id}"
  availability_zone = "${lookup(var.availability_zones, count.index)}"
  cidr_block = "${lookup(var.public_cidr_blocks, count.index)}"
  map_public_ip_on_launch = true
  tags {
    Name = "Mesos Public ${count.index}"
    Subnet = "Public"
  }
}

resource "aws_security_group" "provisioning" {
  name = "provisioning"
  description = "Allow SSH"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Provisioning SG"
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${var.whitelist_ips}"
    ]
  }
}

resource "aws_security_group" "mesos_master" {
  name = "mesos_master"
  description = "Mesos Master"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Master"
  }
}

resource "aws_security_group" "mesos_master_internal" {
  name = "mesos_master_internal"
  description = "Expose Mesos web port"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Master Internal"
  }
  ingress {
    from_port = 5050
    to_port = 5050
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.mesos_slave.id}",
    ]
  }
}

resource "aws_security_group" "mesos_master_external" {
  name = "mesos_master_external"
  description = "Expose Mesos Web UI"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Master External"
  }
  ingress {
    from_port = 5050
    to_port = 5050
    protocol = "tcp"
    cidr_blocks = [
      "${var.whitelist_ips}"
    ]
  }
}

resource "aws_security_group" "marathon" {
  name = "marathon"
  description = "Marathon"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Marathon"
  }
}

resource "aws_security_group" "marathon_external" {
  name = "marathon_external"
  description = "Expose Marathon Web UI"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Marathon External"
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      "${var.whitelist_ips}"
    ]
  }
}

resource "aws_security_group" "marathon_internal" {
  name = "marathon_internal"
  description = "Expose marathon API to haproxy and mesos master"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Marathon Internal"
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.haproxy.id}",
      "${aws_security_group.mesos_master.id}",
    ]
  }
}

resource "aws_security_group" "elb" {
  name = "elb"
  description = "Elastic Load Balancer"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "ELB"
    ELB = "true"
    Public = "true"
    Private = "true"
  }
}

resource "aws_security_group" "elb_external" {
  name = "elb_external"
  description = "Expose Services to Internet"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "ELB External"
    ELB = "true"
    Public = "true"
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_internal" {
  name = "elb_internal"
  description = "Expose Services to Each Other"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "ELB Internal"
    ELB = "true"
    Private = "true"
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.mesos_slave.id}",
    ]
  }
}

resource "aws_security_group" "haproxy" {
  name = "haproxy"
  description = "HAProxies that perform Mid-Tier Load Balancing"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "HAProxy"
    HAProxy = "true"
  }
}

resource "aws_security_group" "haproxy_internal" {
  name = "haproxy_internal"
  description = "Expose HAProxy to ELBs"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "HAProxy Internal"
    HAProxy = "true"
  }
  ingress {
    from_port = 10000
    to_port = 20000
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.elb.id}"
    ]
  }
}

resource "aws_security_group" "mesos_slave" {
  name = "mesos_slave"
  description = "Mesos Slave"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Slave"
  }
}

resource "aws_security_group" "mesos_slave_internal" {
  name = "mesos_slave_internal"
  description = "Expose mesos tasks to haproxy and web api to mesos master"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Slave Internal"
    MarathonApp = "true"
  }
  ingress {
    from_port = 31000
    to_port = 32000
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.haproxy.id}"
    ]
  }
  ingress {
    from_port = 5051
    to_port = 5051
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.mesos_master.id}"
    ]
  }
}

resource "aws_security_group" "mesos_slave_external" {
  name = "mesos_slave_external"
  description = "Expose mesos slave web UI"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Mesos Slave External"
  }
  ingress {
    from_port = 5051
    to_port = 5051
    protocol = "tcp"
    cidr_blocks = [
      "${var.whitelist_ips}"
    ]
  }
}

resource "aws_security_group" "mesos_framework_private" {
  name = "mesos_framework_private"
  description = "Expose mesos masters, slaves, and frameworks to each other"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Private Mesos"
  }
  ingress {
    self = true
    from_port = 5050
    to_port = 5051
    protocol = "tcp"
  }
  ingress {
    self = true
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
  }
  ingress {
    self = true
    from_port = 0
    to_port = 65535
    protocol = "tcp"
  }
}

resource "aws_security_group" "kafka" {
  name = "kafka"
  description = "Kafka Security Group"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Kafka"
  }
}

resource "aws_security_group" "kafka_internal" {
  name = "kafka_internal"
  description = "Kafka Internal"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Kafka"
  }
  ingress {
    self = true
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.provisioning.id}"
    ]
  }
}

resource "aws_security_group" "zookeeper" {
  name = "zookeeper"
  description = "Zookeeper"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Zookeeper"
  }
}

resource "aws_security_group" "zookeeper_private" {
  name = "zookeeper_private"
  description = "Private communication for zookeeper cluster"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Zookeeper Private"
  }
  ingress {
    self = true
    from_port = 2888
    to_port = 2888
    protocol = "tcp"
  }
  ingress {
    self = true
    from_port = 3888
    to_port = 3888
    protocol = "tcp"
  }
}

resource "aws_security_group" "zookeeper_internal" {
  name = "zookeeper_internal"
  description = "Expose zookeeper to mesos framework and kafka"
  vpc_id = "${aws_vpc.runtime.id}"
  tags {
    Name = "Zookeeper Internal"
  }
  ingress {
    from_port = 2181
    to_port = 2181
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.mesos_master.id}",
      "${aws_security_group.mesos_slave.id}",
      "${aws_security_group.marathon.id}",
      "${aws_security_group.kafka.id}"
    ]
  }
}

resource "aws_instance" "zookeeper" {
  count = "3"
  ami = "${lookup(var.zookeeper_amis, var.region)}"
  instance_type = "m3.xlarge"
  key_name = "${var.keypair}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.provisioning.id}",
    "${aws_security_group.zookeeper.id}",
    "${aws_security_group.zookeeper_private.id}",
    "${aws_security_group.zookeeper_internal.id}",
  ]
  tags {
    Name = "zookeeper"
    VPC = "Mesos VPC"
  }
  user_data = <<DATA
#!/bin/bash

ZOOKEEPER_VERSION=3.4.6

wget http://www.us.apache.org/dist/zookeeper/KEYS
wget http://www.apache.org/dist/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz.asc
wget http://mirror.cc.columbia.edu/pub/software/apache/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz
gpg --import KEYS
gpg --verify zookeeper-$ZOOKEEPER_VERSION.tar.gz.asc zookeeper-$ZOOKEEPER_VERSION.tar.gz

sudo tar -xzf zookeeper-$ZOOKEEPER_VERSION.tar.gz
sudo mv --no-target-directory zookeeper-$ZOOKEEPER_VERSION/ /var/lib/zookeeper

echo "${lookup(var.zk_my_id, count.index)}" | sudo tee /etc/zookeeper/conf/myid

sudo rm -rf /var/zookeeper
sudo mkdir -p /var/lib/zookeeper

echo "tickTime=2000
dataDir=/var/lib/zookeeper/
clientPort=2181
initLimit=5
syncLimit=2
server.1=${lookup(var.zookeeper_ips, 0)}:2888:3888
server.2=${lookup(var.zookeeper_ips, 1)}:2888:3888
server.3=${lookup(var.zookeeper_ips, 2)}:2888:3888 "| sudo tee /etc/zookeeper/conf/zoo.cfg

sudo /var/lib/zookeeper/bin/zkStart.sh
DATA
}

resource "aws_instance" "kafka" {
  count = "5"
  ami = "${lookup(var.zookeeper_amis, var.region)}"
  instance_type = "m3.xlarge"
  key_name = "${var.keypair}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.provisioning.id}",
    "${aws_security_group.kafka.id}",
    "${aws_security_group.kafka_internal.id}",
  ]
  tags {
    Name = "kafka"
    VPC = "Mesos VPC"
  }
  user_data = <<DATA
#!/bin/bash
sudo /etc/init.d/zookeeper stop && true

wget http://apache.cs.utah.edu/kafka/0.8.2.0/kafka_2.10-0.8.2.0.tgz
tar zxvf kafka_2.10-0.8.2.0.tgz
sudo mv kafka_2.10-0.8.2.0 /opt/kafka
rm kafka_2.10-0.8.2.0.tgz

sudo apt-get install -y curl

echo "
broker.id=${count.index}
port=9092
host.name=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
log.dirs=/tmp/kafka-logs
num.recovery.threads.per.data.dir=1
log.cleaner.enable=false
zookeeper.connect=${lookup(var.zookeeper_ips, 0)}:2181,${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 2)}:2181
zookeeper.connection.timeout.ms=6000
zk.sync.time.ms=2000

# Replication configurations
num.replica.fetchers=4
replica.fetch.max.bytes=1048576
replica.fetch.wait.max.ms=500
replica.high.watermark.checkpoint.interval.ms=5000
replica.socket.timeout.ms=30000
replica.socket.receive.buffer.bytes=65536
replica.lag.time.max.ms=10000
replica.lag.max.messages=4000

controller.socket.timeout.ms=30000
controller.message.queue.size=10

# Log configuration
num.partitions=8
message.max.bytes=1000000
auto.create.topics.enable=true
log.index.interval.bytes=4096
log.index.size.max.bytes=10485760
log.retention.hours=168
log.flush.interval.ms=10000
log.flush.interval.messages=20000
log.flush.scheduler.interval.ms=2000
log.roll.hours=168
log.retention.check.interval.ms=300000
log.segment.bytes=1073741824

# Socket server configuration
num.io.threads=8
num.network.threads=8
socket.request.max.bytes=104857600
socket.receive.buffer.bytes=1048576
socket.send.buffer.bytes=1048576
queued.max.requests=16
fetch.purgatory.purge.interval.requests=100
producer.purgatory.purge.interval.requests=100
" | sudo tee /opt/kafka/config/server.properties

sudo /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
DATA
}

resource "aws_instance" "mesos_master" {
  count = "3"
  ami = "${lookup(var.mesos_master_amis, var.region)}"
  instance_type = "m3.xlarge"
  key_name = "${var.keypair}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.provisioning.id}",
    "${aws_security_group.mesos_master.id}",
    "${aws_security_group.mesos_master_internal.id}",
    "${aws_security_group.mesos_master_external.id}",
    "${aws_security_group.mesos_framework_private.id}",
  ]
  tags {
    Name = "mesosmaster"
    VPC = "Mesos VPC"
  }
  user_data = <<DATA
#!/bin/bash

curl -s http://169.254.169.254/latest/meta-data/public-hostname | sudo tee /etc/mesos-master/hostname
curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | sudo tee /etc/mesos-master/ip
echo "zk://${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 2)}:2181/mesos" | sudo tee /etc/mesos/zk
echo "2" | sudo tee /etc/mesos-master/quorum
echo "{var.cluster_name}" | sudo tee /etc/mesos-master/cluster

# Stagger the Mesos Master Start times to prevent crazy race conditions in Zookeeper
sleep ${count.index}0
sudo /etc/init.d/mesos-master start
DATA
}

resource "aws_instance" "mesos_slave" {
  count = "3"
  ami = "${lookup(var.mesos_slave_amis, var.region)}"
  instance_type = "m3.xlarge"
  key_name = "${var.keypair}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.provisioning.id}",
    "${aws_security_group.mesos_slave.id}",
    "${aws_security_group.mesos_slave_internal.id}",
    "${aws_security_group.mesos_slave_external.id}",
    "${aws_security_group.mesos_framework_private.id}"
  ]
  tags {
    Name = "mesosslave"
    VPC = "Mesos VPC"
  }
  user_data = <<DATA
#!/bin/bash

curl -s http://169.254.169.254/latest/meta-data/public-hostname | sudo tee /etc/mesos-slave/hostname
curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | sudo tee /etc/mesos-slave/ip

echo "zk://${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 2)}:2181/mesos" | sudo tee /etc/mesos/zk
echo "docker,mesos" | sudo tee /etc/mesos-slave/containerizers
echo '5mins' | sudo tee /etc/mesos-slave/executor_registration_timeout
echo 'active:yup' | sudo tee /etc/mesos-slave/attributes
echo '{
        "${var.dockerhub_uri}": {
                "auth": "${var.dockerhub_auth}",
                "email": "${var.dockerhub_email}"
        }
}' | sudo tee /etc/.dockercfg

sudo /etc/init.d/mesos-slave start
DATA
}

resource "aws_instance" "marathon" {
  count = "3"
  ami = "${lookup(var.marathon_amis, var.region)}"
  instance_type = "m3.xlarge"
  key_name = "${var.keypair}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.provisioning.id}",
    "${aws_security_group.marathon.id}",
    "${aws_security_group.marathon_internal.id}",
    "${aws_security_group.marathon_external.id}",
    "${aws_security_group.mesos_framework_private.id}",
  ]
  tags {
    Name = "marathon"
    VPC = "Mesos VPC"
  }
  user_data = <<DATA
#!/bin/bash

sudo mkdir -p /etc/marathon/conf/

echo "zk://${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 1)}:2181,${lookup(var.zookeeper_ips, 2)}:2181/mesos" | sudo tee /etc/mesos/zk
curl -s http://169.254.169.254/latest/meta-data/public-hostname | sudo tee /etc/marathon/conf/hostname

sudo /etc/init.d/marathon restart
DATA
}

resource "aws_instance" "haproxy" {
  count = "3"
  ami = "${lookup(var.marathon_load_balancer_amis, var.region)}"
  instance_type = "m3.xlarge"
  key_name = "${var.keypair}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.provisioning.id}",
    "${aws_security_group.haproxy.id}",
    "${aws_security_group.haproxy_internal.id}",
  ]
  tags {
    Name = "haproxy"
    VPC = "Mesos VPC"
    HAProxy = "true"
  }
  user_data = <<DATA
#!/bin/bash
haproxy-marathon-bridge install_haproxy_system "http://${aws_instance.marathon.0.public_dns}:8080"
echo "http://${aws_instance.marathon.0.public_dns}:8080
http://${aws_instance.marathon.1.public_dns}:8080
http://${aws_instance.marathon.2.public_dns}:8080 "| sudo tee /etc/haproxy-marathon-bridge/marathons
DATA
}

resource "aws_route53_record" "mesos" {
  zone_id = "${var.route53_zone_id}"
  name = "mesos-dev.${var.route53_zone_fqdn}"
  type = "CNAME"
  ttl = "30"
  records = ["${aws_instance.mesos_master.0.public_dns}"]
}

resource "aws_route53_record" "marathon" {
  zone_id = "${var.route53_zone_id}"
  name = "marathon-dev.${var.route53_zone_fqdn}"
  type = "CNAME"
  ttl = "30"
  records = ["${aws_instance.marathon.0.public_dns}"]
}
