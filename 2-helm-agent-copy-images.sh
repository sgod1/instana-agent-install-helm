#!/bin/bash

export PATH=".:$PATH"

function copy_image() {
   local src=$1
   local dst=$2
   local override_os=$3
   local override_arch=$4

   local platform="--override-os $override_os --override-arch $override_arch"

   echo copying image $src to $dst

   skopeo copy docker://$src docker://$dst $platform
   rc=$?

   if (( $rc > 0 )); then
      echo rc=$rc, failed to copy $src image to $dst image
      exit 1
   fi
}

# main

source _charts/agent.env
source agent-images.env

source validate-agent-env.sh
source login-registry.sh
source format-image-name.sh
source cluster-vars.sh

cluster=${1:-$(default_cluster_encode)}

validate_agent_env $cluster

# log into instana container registry
login_registry "_" "$DOWNLOAD_KEY" "containers.instana.io"

# log into private container registry host
login_registry "$PRIVATE_REGISTRY_USER" "$PRIVATE_REGISTRY_PASSWORD" "$PRIVATE_REGISTRY_HOST"

# copy images
PRIVATE_REGISTRY=${PRIVATE_REGISTRY_HOST}/${PRIVATE_REGISTRY_SUBPATH}

os=$(valvar $(formatvar AGENT_OS $cluster))
arch=$(valvar $(formatvar AGENT_ARCH $cluster))
reg=$PRIVATE_REGISTRY

src_img="containers.instana.io/instana/release/agent/static:latest"
dst_img=$(format_image_name $os $arch $reg $AGENT_STATIC_IMG $AGENT_TAG)
copy_image $src_img $dst_img $os $arch

src_img="icr.io/instana/instana-agent-operator:latest"
dst_img=$(format_image_name $os $arch $reg $OPERATOR_IMG $OPERATOR_TAG)
copy_image $src_img $dst_img $os $arch

src_img="icr.io/instana/k8sensor:latest"
dst_img=$(format_image_name $os $arch $reg $K8S_SENSOR_IMG $K8S_SENSOR_TAG)
copy_image $src_img $dst_img $os $arch
