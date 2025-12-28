#!/bin/bash

export PATH=".:$PATH"

source cluster-vars.sh

chart_dir="_charts"

mkdir -p $chart_dir

agent_env=$chart_dir/agent.env

if [[ -f $agent_env ]]; then
   echo agent env file $agent_env already exits
   echo make backup and rerun this script
   exit 1
fi

cluster=$1
default_cluster=$(default_cluster_encode)

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
export PRIVATE_REGISTRY_EMAIL=""
export PRIVATE_REGISTRY_PULL_SECRET="private-registry"

# skopeo creds
export REGISTRY_AUTH_FILE=_charts/auth.json

# per target cluster config
# replicate for each cluster

# default cluster config applies when no input
# cluster name is passed on the command line

export $(formatvar KUBECONFIG_CONTEXT $default_cluster)=""
export $(formatvar AGENT_OS $default_cluster)="linux"
export $(formatvar AGENT_ARCH $default_cluster)="" # ppc64le|amd64
export $(formatvar AGENT_CLUSTER_NAME $default_cluster)=""
export $(formatvar AGENT_ZONE_NAME $default_cluster)=""
export $(formatvar AGENT_CONFIG $default_cluster)="helm-agent-config.yaml"
EOF

# this could be a loop over cluster names
if [[ ! -z $cluster ]]; then
cat <<EOF >> $agent_env

export $(formatvar KUBECONFIG_CONTEXT $cluster)=""
export $(formatvar AGENT_OS $cluster)="linux"
export $(formatvar AGENT_ARCH $cluster)="" # ppc64le|amd64
export $(formatvar AGENT_CLUSTER_NAME $cluster)=""
export $(formatvar AGENT_ZONE_NAME $cluster)=""
export $(formatvar AGENT_CONFIG $cluster)="helm-agent-config.yaml"
EOF
fi
