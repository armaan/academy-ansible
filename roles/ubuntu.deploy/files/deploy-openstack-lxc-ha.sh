#!/bin/sh

set -x

CONFIG=~/.juju/openstack-config-lxc.yaml
juju_add() {
  fqdn="$1.`hostname -d`"
  semaphore=~/.juju/hosts/$fqdn
  if [ -e $semaphore ]; then
      echo "Skipping $fqdn because $semaphore exists"
  else
      juju add-machine ssh:$fqdn && touch $semaphore || exit 1
  fi
}

juju_add alice
juju_add bob
juju_add charlie
juju_add daisy
juju_add eric
juju_add frank


juju deploy --config $CONFIG percona-cluster --to lxc:1
juju add-unit percona-cluster --to lxc:3
juju add-unit percona-cluster --to lxc:4
juju deploy hacluster mysql-hacluster
juju add-relation mysql-hacluster percona-cluster

juju deploy rabbitmq-server --to lxc:1
juju add-unit rabbitmq-server --to lxc:3
juju add-unit rabbitmq-server --to lxc:4

juju deploy --config $CONFIG keystone --to lxc:1
juju add-unit keystone --to lxc:4
juju deploy hacluster hacluster-keystone
juju add-relation hacluster-keystone keystone
juju add-relation keystone percona-cluster

juju deploy --config $CONFIG glance --to lxc:1
juju add-unit glance --to lxc:4
juju deploy hacluster hacluster-glance
juju add-relation hacluster-glance glance
juju add-relation glance percona-cluster
juju add-relation glance keystone


juju deploy --config $CONFIG nova-cloud-controller --to lxc:1
juju add-unit nova-cloud-controller --to lxc:4
juju deploy hacluster hacluster-ncc
juju add-relation hacluster-ncc nova-cloud-controller
juju add-relation nova-cloud-controller percona-cluster
juju add-relation nova-cloud-controller rabbitmq-server
juju add-relation nova-cloud-controller glance
juju add-relation nova-cloud-controller keystone

juju deploy --config $CONFIG quantum-gateway --to 3
juju add-relation quantum-gateway mysql
juju add-relation quantum-gateway:amqp rabbitmq-server:amqp
juju add-relation quantum-gateway nova-cloud-controller


sudo juju deploy --config $CONFIG nova-compute --to=2
sudo juju add-relation nova-compute mysql
sudo juju add-relation nova-compute rabbitmq-server
sudo juju add-relation nova-compute glance
sudo juju add-relation nova-compute nova-cloud-controller

juju deploy --config $CONFIG openstack-dashboard --to lxc:1
juju add-unit openstack-dashboard --to lxc:4
juju deploy hacluster horizon-cluster
juju add-relation horizon-cluster openstack-dashboard
juju add-relation openstack-dashboard keystone


juju deploy --config $CONFIG ceph --to 5
juju add-unit ceph --to 6
juju add-unit ceph --to 2
juju add-relation glance ceph
juju add-relation cinder ceph
juju add-relation nova-compute ceph


juju deploy --config $CONFIG cinder --to lxc:3
juju add-unit cinder --to lxc:5
juju add-unit cinder --to lxc:6
juju deploy hacluster cinder-hacluster
juju add-relation cinder cinder-hacluster
juju add-relation cinder percona-cluster
juju add-relation cinder keystone
juju add-relation cinder nova-cloud-controller
juju add-relation cinder rabbitmq-server
juju add-relation cinder ceph
juju add-relation cinder glance

juju deploy heat --to=1
juju add-relation heat keystone
juju add-relation heat percona-cluster
juju add-relation heat rabbitmq-server
