# instana-agent-install-helm
air gapped instana agent helm chart intstall

Install skopeo, helm, oc and add to the path.<br/>
Login into target openshift cluster as cluster admin.<br/>

Use `helm-agent-config.yaml` file to configure instana agent.<br/>

Copy agent environment file template:
```
0-copy-agent-env.sh 
writing _charts/agent.env
```

Update values in `_charts/agent.env`
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

# agent image os and arch
export AGENT_OS="linux"

# ppc64le|amd64
export AGENT_ARCH=""

# required agent customization
export AGENT_CLUSTER_NAME=""
export AGENT_ZONE_NAME=""

# skopeo creds
export REGISTRY_AUTH_FILE=_charts/auth.json
```

Initialize agent namespace
```
0-init-agent-namespace.sh
```

Install:
```
1-helm-agent-download.sh
2-helm-agent-copy-images.sh

export version="agent chart version"
3-helm-agent-install.sh [_charts/instana-agent-${version}.tgz]
```

New version upgrade:
```
1-helm-agent-download.sh
2-helm-agent-copy-images.sh

export version="agent chart version"
3-helm-agent-install.sh _charts/instana-agent-${version}.tgz upgrade
```

Values only (`helm-agent-config.yaml`) update:
```
export version="agent chart version"
3-helm-agent-install.sh _charts/instana-agent-${version}.tgz upgrade
```
