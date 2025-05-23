#!/bin/bash
##
## This scripts runs Tier test in the remote bastion node
##

if [[ "${TIER_TEST}" == "scale" ]]; then
    cd ${WORKSPACE}/ocs-upi-kvm/scripts/; . ${WORKSPACE}/env_vars.sh; ./test-ocs-ci.sh --scale > scale-test.log
    sed -n '/short test summary info/, /Running tier/p' ${WORKSPACE}/ocs-upi-kvm/scripts/scale-test.log | grep -v -i "Running tier" > ${WORKSPACE}/scale-test-summary.txt
    awk '/passed/||/failed/||/skipped/' "${WORKSPACE}/scale-test-summary.txt" | grep "^=" | sed 's/= *//g' | head -1 > "${WORKSPACE}/slacksummary.txt"
else
    cd ${WORKSPACE}/ocs-upi-kvm/scripts/; . ${WORKSPACE}/env_vars.sh; ./test-ocs-ci.sh --tier ${TIER_TEST} > tier${TIER_TEST}.log
    sed -n '/short test summary info/, /Running tier/p' ${WORKSPACE}/ocs-upi-kvm/scripts/tier${TIER_TEST}.log | grep -v -i "Running tier" > ${WORKSPACE}/tier${TIER_TEST}-summary.txt
    awk '/passed/||/failed/||/skipped/' ${WORKSPACE}/tier${TIER_TEST}-summary.txt | grep "^=" | sed 's/= *//g' | head -1 > ${WORKSPACE}/slacksummary.txt

fi
oc adm must-gather --image=quay.io/rhceph-dev/ocs-must-gather:latest-${ODF_VERSION} --dest-dir=${WORKSPACE}/odf-must-gather
tar -cvzf ${WORKSPACE}/odf-must-gather.tar.gz ${WORKSPACE}/odf-must-gather
