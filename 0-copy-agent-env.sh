#!/bin/bash

export PATH=".:$PATH"

chart_dir="_charts"

mkdir -p $chart_dir

agent_env=$chart_dir/agent.env

if [[ -f $agent_env ]]; then
   echo agent env file $agent_env already exits
   echo make backup and rerun this script
   exit 1
fi

echo writing $agent_env

cat <<EOF > $agent_env
export DOWNLOAD_KEY=""
export AGENT_KEY=""

export AGENT_ENDPOINT_HOST=""
export AGENT_ENDPOINT_PORT=""

# private container registry host
export PRIVATE_REGISTRY_HOST=""

# update subpath if needed, eg: sre/instana
export PRIVATE_REGISTRY_SUBPATH="instana"

export PRIVATE_REGISTRY_USER=""
export PRIVATE_REGISTRY_PASSWORD=""
export PRIVATE_REGISTRY_PULL_SECRET="private-registry"

# agent image os and arch
export AGENT_OS="linux"

# ppc64le|amd64
export AGENT_ARCH=""

# required agent customization
export AGENT_CLUSTER_NAME=""
export AGENT_ZONE_NAME=""

# share skopeo/helm creds
export REGISTRY_AUTH_FILE=_charts/auth.json
EOF

