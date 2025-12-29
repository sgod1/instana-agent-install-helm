# instana-agent-install-helm
`Air gapped` instana agent helm chart intstall and upgrade

Install *skopeo*, *helm*, *oc*, *jq* and add to the path.<br/>

You can clone this repo per agent cluster, or configure multiple clusters.<br/>

**Cluster names in configuration**<br/>
Scripts take optional `cluster` argument.<br/>

Optional `cluster` argument is a logical key for the target cluster configuration.<br/>

When ommitted, default is `default_cluster` key.<br/>

Configuration for the `default_cluster` is always included in the agent configuration.<br/>

Per cluster configuration values are used only when cluster key is referenced by the scrit `cluster` argument.<br/>

**Target cluster login**<br/>
Log into target openshift cluster as `cluster admin`.<br/>

Kubeconfig context name is set in agent configuration for each target cluster.<br/>

Run `oc config get-contexts` to view context names for target clusters.<br/>
Current kubeconfig context is marked with the star.<br/>

**Agent image names and architecture**<br/>
Image names are formatted to include agent image os and architecture.<br/>
Agent image os and architecture are defined for each target cluster.<br/>

**Instana helm chart agent configuration**<br/>
Instana agent configuration is defined for each target cluster and passed to `helm` command as second value file.<br/>
`helm-agent-config.yaml` file is used by default to configure instana agent.<br/>
You can place external helm agent conifguration into `_charts/helm-agent-config.yaml`.<br/>

**install | upgrade steps**<br/>
Examples use `default_cluster` target cluster key.<br/>
Double undescore delimits cluster key from configuration keyword.<br/>

*Copy agent environment file template*:
```
0-copy-agent-env.sh [cluster]
writing _charts/agent.env
```

*Update values in* `_charts/agent.env`
```
export DOWNLOAD_KEY=""
export AGENT_KEY=""

export AGENT_ENDPOINT_HOST=""
export AGENT_ENDPOINT_PORT=""

# private container registry host
export PRIVATE_REGISTRY_HOST=""

# update subpath if needed, eg: sre/instana
export PRIVATE_REGISTRY_SUBPATH="instana"

export PRIVATE_REGISTRY_USER=""
export PRIVATE_REGISTRY_PASSWORD=""
export PRIVATE_REGISTRY_EMAIL=""
export PRIVATE_REGISTRY_PULL_SECRET="private-registry"

# skopeo creds
export REGISTRY_AUTH_FILE=_charts/auth.json

# per target cluster config
# replicate for each cluster

# default cluster config applies when no input
# cluster name is passed on the command line

export default_cluster__KUBECONFIG_CONTEXT=""
export default_cluster__AGENT_OS="linux"
export default_cluster__AGENT_ARCH="" # ppc64le|amd64
export default_cluster__AGENT_CLUSTER_NAME=""
export default_cluster__AGENT_ZONE_NAME=""
export default_cluster__AGENT_CONFIG="helm-agent-config.yaml"
```

*Initialize agent namespace*
```
0-init-agent-namespace.sh [cluster]
```

*Install*
```
1-helm-agent-download.sh
2-helm-agent-copy-images.sh [cluster]

export version="agent chart version"
3-helm-agent-install.sh _charts/instana-agent-${version}.tgz install [cluster]
```

*New version upgrade*
```
1-helm-agent-download.sh
2-helm-agent-copy-images.sh [cluster]

export version="agent chart version"
3-helm-agent-install.sh _charts/instana-agent-${version}.tgz upgrade [cluster]
```

*Values only (`helm-agent-config.yaml`) update*
```
export version="agent chart version"
3-helm-agent-install.sh _charts/instana-agent-${version}.tgz upgrade [cluster]
```
