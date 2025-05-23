#!/bin/bash
for osd in $(oc -n openshift-storage rsh $(oc get pods -n openshift-storage | grep rook-ceph-tools | awk '{print $1}') ceph osd ls); do echo "osd $osd"; oc -n openshift-storage rsh $(oc get pods -n openshift-storage | grep rook-ceph-tools | awk '{print $1}') ceph config get osd.$osd bluefs_buffered_io; done
echo "======== Disabling buffered IO ========"
for osd in $(oc -n openshift-storage rsh $(oc get pods -n openshift-storage | grep rook-ceph-tools | awk '{print $1}') ceph osd ls); do oc -n openshift-storage rsh $(oc get pods -n openshift-storage | grep rook-ceph-tools | awk '{print $1}') ceph config set osd.$osd bluefs_buffered_io false; done
for osd in $(oc -n openshift-storage rsh $(oc get pods -n openshift-storage | grep rook-ceph-tools | awk '{print $1}') ceph osd ls); do echo "osd $osd"; oc -n openshift-storage rsh $(oc get pods -n openshift-storage | grep rook-ceph-tools | awk '{print $1}') ceph config get osd.$osd bluefs_buffered_io; done
