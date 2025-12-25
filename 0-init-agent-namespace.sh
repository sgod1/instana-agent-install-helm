#!/bin/bash

function init_agent_namespace() {
   echo ""
   echo initializing instana-agent project

   oc new-project instana-agent
   oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent
   oc adm policy add-scc-to-user anyuid -z instana-agent-remote -n instana-agent
}

function create_image_pull_secret() {
   local secret=$1
   local server=$2
   local user=$3
   local password=$4
   local email=${5:-"hello@world.com"}

   echo ""
   echo creating image pull secret $secret for $server

   oc create secret docker-registry $secret -n instana-agent \
       --docker-server=$server \
       --docker-username=$user \
       --docker-password=$password \
       --docker-email=$email
}

# main

source _charts/agent.env
source validate-agent-env.sh

validate_agent_env

init_agent_namespace

create_image_pull_secret \
   ${PRIVATE_REGISTRY_PULL_SECRET} ${PRIVATE_REGISTRY_HOST} \
   ${PRIVATE_REGISTRY_USER} ${PRIVATE_REGISTRY_PASSWORD} ${PRIVATE_REGISTRY_EMAIL}
