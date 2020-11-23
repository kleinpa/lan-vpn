#!/bin/bash -ue
cd "$(dirname $0)"
source common.sh

# Generate a tag unique to the current minute
tag=$(date +"%Y%m%d%H%M")
echo Using tag ${tag} >&2

# Update images
(   cd "${tools_workspace}"

    bazel_target=//:openvpn_image.tar
    bazel_output=openvpn_image.tar
    image_name=${docker_registry}/${docker_prefix}/server
    bazel build -c opt ${bazel_target}
    crane push $(bazel info -c opt bazel-bin)/${bazel_output} ${image_name}:${tag}
    crane push $(bazel info -c opt bazel-bin)/${bazel_output} ${image_name}:latest

    bazel_target=//exporter/cmd/openvpn_exporter:openvpn_exporter_image.tar
    bazel_output=exporter/cmd/openvpn_exporter/openvpn_exporter_image.tar
    image_name=${docker_registry}/${docker_prefix}/exporter
    bazel build -c opt ${bazel_target}
    crane push $(bazel info -c opt bazel-bin)/${bazel_output} ${image_name}:${tag}
    crane push $(bazel info -c opt bazel-bin)/${bazel_output} ${image_name}:latest

    bazel_target=@com_github_esnet_iperf//:iperf3_image.tar
    bazel_output=external/com_github_esnet_iperf/iperf3_image.tar
    image_name=${docker_registry}/${docker_prefix}/iperf3
    bazel build -c opt ${bazel_target}
    crane push $(bazel info -c opt bazel-bin)/${bazel_output} ${image_name}:${tag}
    crane push $(bazel info -c opt bazel-bin)/${bazel_output} ${image_name}:latest
)

# Upload docker secrets from local docker config
kubectl -n=${kubernetes_namespace} create secret generic regcred \
        --from-file=.dockerconfigjson=$HOME/.docker/config.json \
        --type=kubernetes.io/dockerconfigjson -o yaml --dry-run=client \
    | kubectl -n=${kubernetes_namespace} apply -f -

# Start service
kubectl -n=${kubernetes_namespace} apply -f vpn.yaml

# Generate config
./ca.sh make-server
kubectl -n=${kubernetes_namespace} create configmap lan-vpn-config \
        --from-file=server.conf=${ca_path}/config/server.conf \
        -o yaml --dry-run=client | kubectl replace -f -

# Update image version
kubectl -n=${kubernetes_namespace} set image statefulset/lan-vpn \
        openvpn=${docker_registry}/${docker_prefix}/server:${tag}
kubectl -n=${kubernetes_namespace} set image statefulset/lan-vpn \
        exporter=${docker_registry}/${docker_prefix}/exporter:${tag}

# Restart deployment to force load new config
kubectl -n=${kubernetes_namespace} rollout restart statefulset lan-vpn
