#!/bin/bash

function format_image_name() {
   local os=$1
   local arch=$2
   local registry=$3
   local img=$4
   local tag=$5

   # tag is optional, prepend ":" to non-empty tag
   if [[ ! -z $tag ]]; then
      tag=":${tag}"
   fi

   # add os an arch into image name
   local name=${registry}/${os}_${arch}/${img}${tag}

   echo ${name}
}
