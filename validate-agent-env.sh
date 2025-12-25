#!/bin/bash

export PATH=".:$PATH"

function validate_agent_env() {
   local agent_env="_charts/agent.env"

   if [[ ! -f $agent_env ]]; then
      echo agent env file $agent_env not found
      exit 1
   fi

   echo validating $agent_env

   err="ok"

   if [[ -z $DOWNLOAD_KEY ]]; then echo DOWNLOAD_KEY requred; err="failed"; fi
   if [[ -z $AGENT_KEY ]]; then echo AGENT_KEY required; err="failed"; fi

   if [[ -z $AGENT_ENDPOINT_HOST ]]; then echo AGENT_ENDPOINT_HOST required; err="failed"; fi
   if [[ -z $AGENT_ENDPOINT_PORT ]]; then echo AGENT_ENDPOINT_PORT required; err="failed"; fi

   # private container registry host
   if [[ -z $PRIVATE_REGISTRY_HOST ]]; then echo PRIVATE_REGISTRY_HOST required; err="failed"; fi

   if [[ -z $PRIVATE_REGISTRY_USER ]]; then echo PRIVATE_REGISTRY_USER required; err="failed"; fi
   if [[ -z $PRIVATE_REGISTRY_PASSWORD ]]; then echo PRIVATE_REGISTRY_PASSWORD required; err="failed"; fi
   if [[ -z $PRIVATE_REGISTRY_EMAIL ]]; then echo PRIVATE_REGISTRY_EMAIL required; err="failed"; fi
   if [[ -z $PRIVATE_REGISTRY_PULL_SECRET ]]; then echo PRIVATE_REGISTRY_PULL_SECRET required; err="failed"; fi

   # agent image os and arch
   if [[ -z $AGENT_OS ]]; then echo AGENT_OS required; err="failed"; fi

   # power pc: ppc64le
   if [[ -z $AGENT_ARCH ]]; then echo AGENT_ARCH required; err="failed"; fi

   # required agent customization
   if [[ -z $AGENT_CLUSTER_NAME ]]; then echo AGENT_CLUSTER_NAME required; err="failed"; fi
   if [[ -z $AGENT_ZONE_NAME ]]; then echo AGENT_ZONE_NAME required; err="failed"; fi

   if [[ $err == "failed" ]]; then
      echo $agent_env validation failed
      exit 1
   fi
}

