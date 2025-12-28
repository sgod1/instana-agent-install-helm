#!/bin/bash

export PATH=".:$PATH"

function validate_helm_action() {
   local action=$1

   if [[ (! $action == install) && (! $action == upgrade) ]]; then
      echo invalid helm action $action, actions: install, upgrade
      exit 1
   fi
}

function validate_chart_file() {
   local chart=$1

   if [[ -z $chart ]]; then
      echo instana agent chart name required
      exit 1
   fi

   if [[ ! -f $chart ]]; then
      echo instana agent chart $chart not found
      exit 1
   fi
}

function expand_chart() {
   local chart=$1
   local expand_dir=${2:-"${chart}_tmp"}

   echo ""
   echo expanding chart to $expand_dir
   mkdir -p $expand_dir

   tar xvf $chart -C $expand_dir
   local rc=$?

   if (( $rc > 0 )); then
      echo rc=$rc, failed to expand chart $chart to $expand_dir
      exit 1
   fi
}

function apply_crds() {
   local chart=$1

   # expand chart
   local expand_dir=${chart}_tmp
   expand_chart $chart $expand_dir

   # apply crds
   echo ""
   echo applying crds $expand_dir/instana-agent/crds

   oc apply -f $expand_dir/instana-agent/crds
   rc=$?

   if (( $rc > 0 )); then
      echo rc=$rc, failed to apply crds $expand_dir/instana-agent/crds
      exit 1
   fi
}

# main

source _charts/agent.env
source agent-images.env
source validate-agent-env.sh
source format-image-name.sh
source cluster-vars.sh

# 3-helm-agent-install.sh _charts/chart.tgz install|upgrade [cluster]
chart=$1
helm_action=$2
cluster=${3:-$(default_cluster_encode)}

validate_chart_file $chart

validate_helm_action $helm_action

validate_agent_env $cluster

echo ""
echo ${helm_action}-ing instana agent chart $chart

# concat registry host and subpath
PRIVATE_REGISTRY=$PRIVATE_REGISTRY_HOST/$PRIVATE_REGISTRY_SUBPATH

os=$(valvar $(formatvar AGENT_OS $cluster))
arch=$(valvar $(formatvar AGENT_ARCH $cluster))
reg=$PRIVATE_REGISTRY

# write values yaml
values_yaml="_charts/agent-values-${cluster}.yaml"

echo ""
echo writing values file $values_yaml

cat <<EOF > $values_yaml
openshift: true

cluster:
  name: $(valvar $(formatvar AGENT_CLUSTER_NAME $cluster))

zone:
  name: $(valvar $(formatvar AGENT_ZONE_NAME $cluster))

agent:
  endpointHost: $AGENT_ENDPOINT_HOST
  endpointPort: $AGENT_ENDPOINT_PORT
  key: $AGENT_KEY

  image:
    name: $(format_image_name $os $arch $reg $AGENT_STATIC_IMG)
    tag: $AGENT_TAG

    pullSecrets:
    - name: $PRIVATE_REGISTRY_PULL_SECRET

k8s_sensor:
  image:
    name: $(format_image_name $os $arch $reg $K8S_SENSOR_IMG)
    tag: $K8S_SENSOR_TAG

controllerManager:
  image:
    name: $(format_image_name $os $arch $reg $OPERATOR_IMG)
    tag: $OPERATOR_TAG

    pullSecrets:
    - name: $PRIVATE_REGISTRY_PULL_SECRET
EOF

# agent configuration for the helm chart
agent_config=$(formatvar AGENT_CONFIG $cluster)
agent_conf_yaml=$(valvar $agent_config)
if [[ ! -f $agent_conf_yaml ]]; then
   echo agent config file $agent_conf_yaml not found, key $agent_config
   exit 1
fi

# apply crds
apply_crds $chart

echo ""
echo ${helm_action}-ing agent chart $chart with values $values_yaml, $agent_conf_yaml

set -x
helm $helm_action -f $values_yaml -f $agent_conf_yaml instana-agent -n instana-agent $chart --wait --timeout 60m0s
