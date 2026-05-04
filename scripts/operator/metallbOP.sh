#!/bin/bash
echo 'Creating var.yaml'
rm -rf ~/.ansible
ansible all -m setup -a 'gather_subset=!all'
cd ${WORKSPACE}/ocp4-playbooks-extras
cp examples/metallb_vars.yml metallb_vars.yml
sed -i "s|metallb_enabled:.*$|metallb_enabled: true|g" metallb_vars.yml
sed -i "s|metallb_enable_global_secret:.*$|metallb_enable_global_secret: false|g" metallb_vars.yml
sed -i "s|ocp_version:.*|ocp_version: ${OCP_RELEASE}|g" metallb_vars.yml
sed -i "s|metallb_golang_tarball:.*$|metallb_golang_tarball: ${GOLANG_TARBALL}|g" metallb_vars.yml
sed -i "s|metallb_openshift_tests_private_git_branch:.*$|metallb_openshift_tests_private_git_branch: main|g" metallb_vars.yml
sed -i "s|metallb_catalog_source_image:.*$|metallb_catalog_source_image: ${METALLB_CATALOGSOURCE_IMAGE}|g" metallb_vars.yml
sed -i "s|metallb_e2e_git_branch:.*$|metallb_e2e_git_branch: release-${OCP_RELEASE}|g" metallb_vars.yml
yq -iy ".l2_address = [\"${L2_ADDRESS1}\", \"${L2_ADDRESS2}\"] | .bgp_address = [\"${BGB_ADDRESS1}\"]" metallb_vars.yml
cat metallb_vars.yml
#Inventory Details
cp examples/inventory ./metallb_inventory
sed -i "s|localhost|${BASTION_IP}|g" metallb_inventory
sed -i 's/ansible_connection=local/ansible_connection=ssh/g' metallb_inventory
sed -i "s|ssh|ssh ansible_ssh_private_key_file=${WORKSPACE}/deploy/id_rsa|g" metallb_inventory
cat metallb_inventory
cat ansible.cfg
export GITHUB_USERNAME=${GITHUB_USER}
export GITHUB_ACCESS_TOKEN=${GITHUB_TOKEN}
#ansible bastion -i metallb_inventory  -m shell -a "oc create secret generic podman-secret --from-literal=username=\"${PODMAN_USERNAME}\" --from-literal=password=\"${PODMAN_PASSWORD}\" --from-literal=registry=\"${PODMAN_REGISTRY}\" --type=kubernetes.io/basic-auth --namespace=default"
ansible-playbook  -i metallb_inventory -e @metallb_vars.yml playbooks/ocp-metallb-operator.yml