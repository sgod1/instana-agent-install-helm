#!/bin/bash

function kubeconfig_use_context() {
   local cluster=$1
   local context=$2
   local rc=0

   oc config use-context $context; rc=$?
   if (( rc > 0 )); then echo rc=$rc, context $context not found, cluster key $cluster; exit 1; fi

   context_cluster_name=`oc config get-contexts | grep "*" | tr -s ' ' | cut -d' ' -f3`; rc=$?
   if (( rc > 0 )); then echo failed to get cluster name from current context $context; exit 1; fi

   echo current context: $context, cluster name: $context_cluster_name

   oc config view --minify -ojson | jq ".clusters[]|select(.name==\"${context_cluster_name}\")"; rc=$?
   if (( rc > 0 )); then echo rc=$rc, oc config view error; exit 1; fi
}
