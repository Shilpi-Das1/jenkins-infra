#!/bin/bash

# Get health from CephCluster CRD
health=$(oc get cephcluster -n openshift-storage -o jsonpath='{.items[0].status.ceph.health}')

# Optional: uncomment for debugging
# echo "CephCluster CRD Health: $health"

if [[ "$health" == "HEALTH_OK" ]]; then
  echo "Ceph cluster is healthy."
  exit 0
else
  echo "Ceph cluster is NOT healthy. Status: $health"
  exit 1
fi