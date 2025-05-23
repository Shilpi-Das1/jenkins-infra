#!/bin/bash
echo "===== $(date) Checking CRC Logs =====" 
                        
# Get all OSD pod names in the openshift-storage namespace
pods=$(kubectl get pods -n openshift-storage -l app=rook-ceph-osd -o jsonpath='{.items[*].metadata.name}')
for pod in $pods; do
    echo "Logs from $pod at $(date)"
    kubectl logs -n openshift-storage "$pod" | grep  "crc" || true
done