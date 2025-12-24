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

validate_agent_env

# log into instana container registry
login_registry "_" "$DOWNLOAD_KEY" "containers.instana.io"

# log into private container registry host
login_registry "$PRIVATE_REGISTRY_USER" "$PRIVATE_REGISTRY_PASSWORD" "$PRIVATE_REGISTRY_HOST"

# copy images
PRIVATE_REGISTRY=${PRIVATE_REGISTRY_HOST}/${PRIVATE_REGISTRY_SUBPATH}

src_img="containers.instana.io/instana/release/agent/static:latest"
dst_img="${PRIVATE_REGISTRY}/${AGENT_STATIC_IMG}:${AGENT_TAG}"
copy_image $src_img $dst_img $AGENT_OS $AGENT_ARCH

src_img="icr.io/instana/instana-agent-operator:latest"
dst_img="${PRIVATE_REGISTRY}/${OPERATOR_IMG}:${OPERATOR_TAG}"
copy_image $src_img $dst_img $AGENT_OS $AGENT_ARCH

src_img="icr.io/instana/k8sensor:latest"
dst_img="${PRIVATE_REGISTRY}/${K8S_SENSOR_IMG}:${K8S_SENSOR_TAG}"
copy_image $src_img $dst_img $AGENT_OS $AGENT_ARCH
