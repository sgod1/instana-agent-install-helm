#!/bin/bash

function kubeconfig_use_context() {
   local cluster=$1
   local context=$2
   local rc=0

   oc config use-context $context; rc=$?
   if (( rc > 0 )); then echo rc=$rc, context $context not found, cluster key $cluster; exit 1; fi

   context_cluster_name=`oc config get-contexts | grep "*" | cut -d' ' -f59`; rc=$?
   if (( rc > 0 )); then echo failed to get cluster name from current context $context; exit 1; fi

   echo current context: $context, cluster name: $context_cluster_name

   oc config view --minify -ojson | jq ".clusters[]|select(.name==\"${context_cluster_name}\")"; rc=$?
   if (( rc > 0 )); then echo rc=$rc, oc config view error; exit 1; fi
}

function init_agent_namespace() {
   cluster=$1
   local rc=0

   echo ""
   echo initializing instana-agent namespace

   oc get project instana-agent 2>/dev/null; rc=$?
   if (( rc==0 )); then
      echo instana-agent namespace exits

   else
      echo creating instana-agent namespace
      oc new-project instana-agent; rc=$?
      if (( rc > 0 )); then echo rc=$rc, failed to create instana-agent namespace; exit 1; fi
   fi

   oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent; rc=$?
   if (( rc > 0 )); then echo rc=$rc, add-scc-to-user privileged failed, sa instana-agent, namespace instana-agent; exit 1; fi

   oc adm policy add-scc-to-user anyuid -z instana-agent-remote -n instana-agent; rc=$?
   if (( rc > 0 )); then echo rc=$rc, add-scc-to-user anyuid failed, sa instana-agent, namespace instana-agent; exit 1; fi
}

function create_image_pull_secret() {
   local secret=$1
   local server=$2
   local user=$3
   local password=$4
   local email=${5:-"hello@world.com"}

   oc get secret $secret -n instana-agent 2>/dev/null; rc=$?
   if (( rc == 0 )); then
      echo found image pull secret $secret

   else
      echo ""
      echo creating image pull secret: $secret for $server

      oc create secret docker-registry $secret -n instana-agent \
         --docker-server=$server \
         --docker-username=$user \
         --docker-password=$password \
         --docker-email=$email; rc=$?

      if (( rc > 0 )); then echo rc=$rc, failed to create image pull secret $secret; exit 1; fi
   fi
}

# main

source _charts/agent.env
source validate-agent-env.sh
source cluster-vars.sh

cluster=${1:-$(default_cluster_encode)}

validate_agent_env $cluster

displayvar AGENT_CLUSTER_NAME $cluster
displayvar KUBECONFIG_CONTEXT $cluster

context=$(valvar $(formatvar KUBECONFIG_CONTEXT $cluster))

kubeconfig_use_context $cluster $context

init_agent_namespace $cluster

create_image_pull_secret \
   ${PRIVATE_REGISTRY_PULL_SECRET} ${PRIVATE_REGISTRY_HOST} \
   ${PRIVATE_REGISTRY_USER} ${PRIVATE_REGISTRY_PASSWORD} ${PRIVATE_REGISTRY_EMAIL}
