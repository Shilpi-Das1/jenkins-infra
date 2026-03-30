#!/bin/bash
set -e

echo "Creating lso_vars.yaml"

rm -rf ~/.ansible
ansible all -m setup -a 'gather_subset=!all'

cd ${WORKSPACE}/ocp4-playbooks-extras

cp examples/ocp_lso_vars.yaml lso_vars.yaml

sed -i "s|lso_enabled:.*$|lso_enabled: true|g" lso_vars.yaml
sed -i "s|lso_namespace:.*$|lso_namespace: openshift-local-storage|g" lso_vars.yaml
sed -i "s|lso_channel:.*$|lso_channel: stable|g" lso_vars.yaml

if [ -n "${LSO_CATALOGSOURCE_IMAGE}" ]; then
  echo "Using custom catalog source for LSO"
  sed -i "s|lso_catalogsource_name:.*$|lso_catalogsource_name: my-operator-catalog|g" lso_vars.yaml
  sed -i "s|lso_catalogsource_image:.*$|lso_catalogsource_image: ${LSO_CATALOGSOURCE_IMAGE}|g" lso_vars.yaml
else
  echo "Using default redhat-operators catalog"
  sed -i "s|lso_catalogsource_name:.*$|lso_catalogsource_name: redhat-operators|g" lso_vars.yaml
  sed -i "s|lso_catalogsource_image:.*$|lso_catalogsource_image: ''|g" lso_vars.yaml
fi

sed -i "s|busybox_image:.*$|busybox_image: quay.io/powercloud/busybox:ubi|g" lso_vars.yaml
sed -i "s|upi_cluster:.*$|upi_cluster: true|g" lso_vars.yaml
sed -i "s|device_path:.*$|device_path: /dev/lso|g" lso_vars.yaml
sed -i "s|lso_enable_global_secret :.*$|lso_enable_global_secret: false|g" lso_vars.yaml
cat lso_vars.yaml

cp examples/inventory ./lso_inventory
sed -i "s|localhost|${BASTION_IP}|g" lso_inventory
sed -i 's/ansible_connection=local/ansible_connection=ssh/g' lso_inventory
sed -i "s|ssh|ssh ansible_ssh_private_key_file=${WORKSPACE}/deploy/id_rsa|g" lso_inventory

ansible-playbook -i lso_inventory -e @lso_vars.yaml playbooks/ocp-lso.yml
