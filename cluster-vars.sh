#!/bin/bash

function formatvar() {
   local var=$1
   local cluster=$2 
   local prefix="${cluster}__"
   if [[ -z $cluster ]]; then prefix=""; fi
   echo ${prefix}${var}
}

function valvar() {
   local var=$1
   echo ${!var}
}

function checkvar() {
   local var=$1
   local val=${!var}
   local rc=0
   if [[ -z $val ]]; then echo $var required; ((rc=1)); fi
   return $rc
}

function displayvar() {
    local var=$1
    local cluster=$2
    local fvar=$(formatvar $var $cluster)
    echo $fvar=$(valvar $fvar)
}

function default_cluster_encode() {
    echo "default_cluster"
}
