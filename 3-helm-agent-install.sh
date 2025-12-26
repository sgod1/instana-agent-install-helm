#!/bin/bash

export PATH=".:$PATH"

# local functions

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

function find_agent_config() {
   local conf_yaml=$1
   local charts_conf_yaml="_charts/$conf_yaml" 

   if [[ -f $charts_conf_yaml ]]; then conf_yaml=$charts_conf_yaml; fi

   echo $conf_yaml
}

function validate_helm_action() {
   local action=$1

   if [[ (! $action == install) && (! $action == upgrade) ]]; then
      echo invalid helm action $action, actions: install, upgrade
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

echo ... prereqs ...
echo oc command is on the path
echo helm command is on the path
echo log into target openshift as cluster admin
echo ...

_chart_dir="_charts"

source $_chart_dir/agent.env
source agent-images.env
source validate-agent-env.sh
source format-image-name.sh

# 3-helm-agent-install.sh [_charts/chart.tgz [install|upgrade]]
input_chart=$1
helm_action=${2:-"install"}

validate_helm_action $helm_action

validate_agent_env

chart=${input_chart:-$(find_agent_chart $_chart_dir)}

if [[ ! -f $chart ]]; then
   echo instana agent chart $chart not found
   exit 1
fi

echo ""
echo ${helm_action}-ing instana agent chart $chart

# concat registry host and subpath
PRIVATE_REGISTRY=$PRIVATE_REGISTRY_HOST/$PRIVATE_REGISTRY_SUBPATH

os=$AGENT_OS
arch=$AGENT_ARCH
reg=$PRIVATE_REGISTRY

# write values yaml
values_yaml="$_chart_dir/agent-values.yaml"

echo ""
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

# agent configuration for the helm chart: helm-agent-config.yaml
# place external helm agent configuration file into _charts/helm-agent-config.yaml
agent_conf_yaml=$(find_agent_config "helm-agent-config.yaml")

# apply crds
apply_crds $chart

echo ""
echo ${helm_action}-ing agent chart $chart with values $values_yaml, $agent_conf_yaml

set -x
helm $helm_action -f $values_yaml -f $agent_conf_yaml instana-agent -n instana-agent $chart --wait --timeout 60m0s
