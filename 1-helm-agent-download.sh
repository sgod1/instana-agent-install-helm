#!/bin/bash

export PATH=".:$PATH"

chart_dir="_charts"

mkdir -p $chart_dir

version="latest"

echo pulling agent chart from https://agents.instana.io/helm, version $version

helm pull --repo https://agents.instana.io/helm instana-agent -d $chart_dir
rc=$?
if (( $rc > 0 )); then
   echo rc $rc, failed to pull chart instana-chart from https://agents.instana.io/helm
   exit 1
fi

agent_charts=`find $chart_dir -name instana-agent*.tgz`

echo downloaded agent charts... $agent_charts
