#!/bin/bash

function login_registry() {
   local user=$1
   local password=$2
   local registry=$3

   echo logging into container registry $registry

   skopeo login --tls-verify=false -u $user -p $password $registry
   rc=$?
   if (( $rc > 0 )); then
      echo rc=$rc, failed to log into container registry $registry
      exit 1
   fi
}
