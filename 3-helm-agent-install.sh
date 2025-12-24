#!/bin/bash

export PATH=".:$PATH"

function find_agent_chart() {
   local cdir=$1
   num_tars=`find $cdir -name "instana-agent*tgz" | wc -l`

   if (( $num_tars > 1 )); then
      echo more than one agent chart file found
      find . -name "instana-agent*tgz"
      echo pass agent chart file as input
      exit 1
   fi

   echo `find . -name "instana-agent*tgz"`
}

# main
_chart_dir="_charts"

source $_chart_dir/agent.env
source agent-images.env
source validate-agent-env.sh

# 3-helm-agent-install.sh [chart.tgz [install|upgrade]]

input_chart=$1
helm_action=${2:-"install"}

if [[ (! $helm_action == install) && (! $helm_action == upgrade) ]]; then
   echo invalid helm action $helm_action, actions: install, upgrade
   exit 1
fi

echo ... prereqs ...
echo oc command is on the path
echo helm command is on the path
echo logged into target openshift as cluster admin
echo ...

validate_agent_env

chart=${input_chart:-$(find_agent_chart $_chart_dir)}

if [[ ! -f $chart ]]; then
   echo instana agent chart $chart not found
   exit 1
fi

echo installing instana agent chart $chart

oc new-project instana-agent
oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent
oc adm policy add-scc-to-user anyuid -z instana-agent-remote -n instana-agent

# create image pull secet
oc create secret docker-registry $PRIVATE_REGISTRY_PULL_SECRET -n instana-agent \
    --docker-server=$PRIVATE_REGISTRY_HOST \
    --docker-username=$PRIVATE_REGISTRY_USER \
    --docker-password=$PRIVATE_REGISTRY_PASSWORD \
    --docker-email="hello@world.com"

# registry host and subpath
PRIVATE_REGISTRY=$PRIVATE_REGISTRY_HOST/$PRIVATE_REGISTRY_SUBPATH

values_yaml="$_chart_dir/agent-values.yaml"

echo writing values file $values_yaml

cat <<EOF > $values_yaml
openshift: true

cluster:
  name: $AGENT_CLUSTER_NAME

zone:
  name: $AGENT_ZONE_NAME

agent:
  endpointHost: $AGENT_ENDPOINT_HOST
  endpointPort: $AGENT_ENDPOINT_PORT
  key: $AGENT_KEY

  image:
    name: $PRIVATE_REGISTRY/$AGENT_STATIC_IMG
    tag: $AGENT_TAG

    pullSecrets:
    - name: $PRIVATE_REGISTRY_PULL_SECRET

k8s_sensor:
  image:
    name: $PRIVATE_REGISTRY/$K8S_SENSOR_IMG
    tag: $K8S_SENSOR_TAG

controllerManager:
  image:
    name: $PRIVATE_REGISTRY/$OPERATOR_IMG
    tag: $OPERATOR_TAG

    pullSecrets:
    - name: $PRIVATE_REGISTRY_PULL_SECRET
EOF

# agent configuration for the helm chart
agent_conf_yaml="helm-agent-config.yaml"

echo ${helm_action}ing agent chart $chart with values $values_yaml, $agent_conf_yaml

set -x
helm $helm_action -f $values_yaml -f $agent_conf_yaml instana-agent -n instana-agent $chart --wait --timeout 60m0s
