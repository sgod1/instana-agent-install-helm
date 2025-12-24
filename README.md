# instana-agent-install-helm
air gapped instana agent helm chart intstall

```
./0-copy-agent-env.sh 
writing _charts/agent.env
```

Update values in _charts/agent.env
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
export PRIVATE_REGISTRY_PULL_SECRET="private-registry"

# agent image os and arch
export AGENT_OS="linux"

# ppc64le|amd64
export AGENT_ARCH=""

# required agent customization
export AGENT_CLUSTER_NAME=""
export AGENT_ZONE_NAME=""

# share skopeo/helm creds
export REGISTRY_AUTH_FILE=_charts/auth.json
```

Run:
```
1-helm-agent-download.sh
2-helm-agent-copy-images.sh
3-helm-agent-install.sh
```
