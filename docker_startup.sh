#!/bin/bash
echo "***** Checkout the flexswitch base image *******"
docker pull snapos/flex:latest

echo "***** Spawn 2 docker instances d_inst1 d_inst2"

docker run -dt --privileged --log-driver=syslog --cap-add=ALL  --name d_inst1   -P snapos/flex:latest
docker run -dt --privileged --log-driver=syslog --cap-add=ALL --name d_inst2 -P snapos/flex:latest

sleep 20

d1_pid=`docker inspect -f '{{.State.Pid}}' d_inst1`
d2_pid=`docker inspect -f '{{.State.Pid}}' d_inst2`

mkdir -p /var/run/netns

ln -s /proc/$d1_pid/ns/net /var/run/netns/$d1_pid
ln -s /proc/$d2_pid/ns/net /var/run/netns/$d2_pid

echo -e "done!\n"

sudo ip link add eth25 type veth peer name eth35

sudo ip link set eth25 netns $d1_pid
sudo ip netns exec $d1_pid ip link set eth25 up

sudo ip link set eth35 netns $d2_pid
sudo ip netns exec $d2_pid  ip link set eth35 up


echo -e "Start flexswtich to pick up the interfaces "
echo "##############################"
echo "#######d_inst1 FS restart######"
echo "##############################"
docker exec  d_inst1 sh -c "/etc/init.d/flexswitch restart"
echo "##############################"
echo "#######d_inst2 FS restart######"
echo "##############################"
docker exec  d_inst2 sh -c "/etc/init.d/flexswitch restart"

