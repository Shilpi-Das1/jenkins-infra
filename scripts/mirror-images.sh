#!/bin/bash
# Added 4hrs to 24hrs if any delay in imagestream creation
compare_time=$(date -d  "1128 hour ago" "+%s")
public_repo=$(./oc get is release-ppc64le -n ocp-ppc64le -o=json | jq -r -c '.status.publicDockerImageRepository')
target_repo="${DOCKER_REGISTRY}/ocp-ppc64le/release-ppc64le"

echo here is the public repo: $public_repo
echo "--------here failed0"
for annotation in $(./oc get is release-ppc64le -n ocp-ppc64le -o=json | jq -c '.spec.tags[]'); do
    _jq() {
     echo "${annotation}"| jq -r ${1}
    }
echo "--------here failed1"
    creation_time=$(_jq '.annotations."release.openshift.io/creationTimestamp"')
    echo "--------here failed2"
    if [ "$creation_time" == "null" ]; then
       continue
    fi
        creation_timestamp=$(date -d "${creation_time}" "+%s")
echo "--------here failed3"
        # Check if the creation timestamp is greater than the compare timestamp
        if [ "${creation_timestamp}" -gt "${compare_time}" ]; then
        echo "--------here failed4"
        tag=$(_jq '.name')
        echo "--------here failed5"
        checkif_imageAlreadyPresent=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${ARTIFACTORY_TOKEN}" "https://na.artifactory.swg-devops.com/artifactory/sys-powercloud-docker-local/ocp-ppc64le/release-ppc64le/$tag/")
        if [ ! "${checkif_imageAlreadyPresent}" == "200" ]; then
            echo "image is not present ${target_repo}:${tag}"
            nerdctl pull ${public_repo}:${tag}
            nerdctl tag ${public_repo}:${tag} ${target_repo}:${tag}
            nerdctl push ${target_repo}:${tag}
            nerdctl rmi ${public_repo}:${tag} ${target_repo}:${tag} ${target_repo}:${tag}-tmp-single
        fi
    fi
done

# Pulling EC builds
curl https://ppc64le.ocp.releases.ci.openshift.org/api/v1/releasestream/4-dev-preview-ppc64le/latest > build.txt
ec_build=$(jq ".pullSpec"  build.txt |tr -d '"')
ec_tag=$(jq ".name"  build.txt |tr -d '"')
checkif_imageAlreadyPresent=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${ARTIFACTORY_TOKEN}" "https://na.artifactory.swg-devops.com/artifactory/sys-powercloud-docker-local/ocp-ppc64le/release-ppc64le/$ec_tag/")
if [ ! "${checkif_imageAlreadyPresent}" == "200" ]; then
    nerdctl pull $ec_build
    nerdctl tag $ec_build ${target_repo}:$ec_tag
    nerdctl push ${target_repo}:$ec_tag
    nerdctl rmi $ec_build ${target_repo}:$ec_tag ${target_repo}:$ec_tag-tmp-single
fi