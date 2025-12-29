#!/bin/bash

export PATH=".:$PATH"

source cluster-vars.sh

function validate_agent_env() {
   local cluster=${1:-$(default_cluster_encode)}

   local agent_env="_charts/agent.env"

   if [[ ! -f $agent_env ]]; then
      echo agent env file $agent_env not found >&2
      exit 1
   fi

   echo validating $agent_env

   local errsum=0

   # agent keys
   checkvar DOWNLOAD_KEY
   ((errsum+=$?))
   
   checkvar AGENT_KEY
   ((errsum+=$?))

   # agent endpoint
   checkvar AGENT_ENDPOINT_HOST
   ((errsum+=$?))

   checkvar AGENT_ENDPOINT_PORT
   ((errsum+=$?))

   # private container registry
   checkvar PRIVATE_REGISTRY_HOST
   ((errsum+=$?))

   checkvar PRIVATE_REGISTRY_USER
   ((errsum+=$?))

   checkvar PRIVATE_REGISTRY_PASSWORD
   ((errsum+=$?))

   checkvar PRIVATE_REGISTRY_EMAIL
   ((errsum+=$?))

   checkvar PRIVATE_REGISTRY_PULL_SECRET
   ((errsum+=$?))

   # cluster specific settings

   # kubeconfig context
   checkvar $(formatvar KUBECONFIG_CONTEXT $cluster)
   ((errsum+=$?))

   # agent image os and arch
   checkvar $(formatvar AGENT_OS $cluster)
   ((errsum+=$?))

   # power pc: ppc64le
   checkvar $(formatvar AGENT_ARCH $cluster)
   ((errsum+=$?))

   # required agent customization
   checkvar $(formatvar AGENT_CLUSTER_NAME $cluster)
   ((errsum+=$?))

   checkvar $(formatvar AGENT_ZONE_NAME $cluster)
   ((errsum+=$?))

   checkvar $(formatvar AGENT_CONFIG $cluster)
   ((errsum+=$?))

   if (( errsum > 0 )); then
      echo $agent_env validation failed
      exit 1
   fi
}
