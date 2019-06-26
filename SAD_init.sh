#!/bin/sh
# Check Requirements
if [ $(id -u) -ne 0 ]; then echo "Must be run as root"; exit 1; fi
if [ $# -lt 2 ]; then echo "SAD_init.sh <count> <latency>"; exit 1; fi

# Actual Setup
count=$1
latency=$2
# rootSvr
lxc init sadImg rootSvr
lxc network attach lxdbr0 rootSvr eth0
lxc config device set rootSvr eth0 ipv4.address 10.0.10.10
lxc start rootSvr
# comSvr
lxc init sadImg comSvr
lxc network attach lxdbr0 comSvr eth0
lxc config device set comSvr eth0 ipv4.address 10.0.10.11
lxc start comSvr
# teamSvr
lxc init sadImg teamSvr
lxc network attach lxdbr0 teamSvr eth0
lxc config device set teamSvr eth0 ipv4.address 10.0.10.12
lxc start teamSvr
# locSvr
lxc init sadImg locSvr
lxc network attach lxdbr0 locSvr eth0
lxc config device set locSvr eth0 ipv4.address 10.0.10.13
lxc start locSvr
# atkSvr
lxc init sadImg atkSvr
lxc network attach lxdbr0 atkSvr eth0
lxc config device set atkSvr eth0 ipv4.address 10.0.10.14
lxc start atkSvr

# Scripts
echo "Running Setup Scripts"
lxc exec rootSvr -- /root/scripts/rootSvr_init.sh
lxc exec comSvr -- /root/scripts/comSvr_init.sh $count
lxc exec teamSvr -- /root/scripts/teamSvr_init.sh $count $latency
lxc exec locSvr -- /root/scripts/locSvr_init.sh
lxc exec atkSvr -- /root/scripts/atkSvr_init.sh $count