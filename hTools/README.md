# hTools
This folder contains a set of scripts, documentation and yaml helm files to ease the helm chores.
## Index
- [hTools](#htools)
  - [Index](#index)
  - [Utils chart](#utils-chart)
  - [View the names of the downloaded repos](#view-the-names-of-the-downloaded-repos)
  - [Search all the versions for a repo/chart](#search-all-the-versions-for-a-repochart)
    - [Install yq](#install-yq)
    - [Install jq](#install-jq)
## Utils chart
The file utils.yaml contains a set of tools can be copied into the template's helm folder of your helm chart.  
```
|<helmFolder>
 |- templates
  |- utils.yaml
 |- Chart.yaml
 |- values.yaml
```

This Helm yaml file defines the components to install a couple of utilities.
- utils-nettools: results in a pod with tools like nslookup, curl, wget, ping, ... installed.
- utils-echo: results in a pod that expose several server informations.  
The value file structure to deploy these tools can be something similar to:
```
utils:
  enabled: true
  echo:
    enabled: true
    ingress: 
      enabled: true
      tls:
        # []
        - hosts: [MyDNS.com]
          secretName: [MySecretWithTLSCredentials]
      hosts: 
        # []
        ## provide a hosts and the paths that should be available          
        - host: MyDNS.com
```

Once deployed, the URL https://MyDNS.com/echo will show a set of server informations.

## View the names of the downloaded repos
```
helm repo list  
```
## Search all the versions for a repo/chart
eg: bitnami/keycloak:
```
helm search repo <repoName>/<chartName> --versions  
```

Examples:
```
helm search repo bitnami/keycloak --versions
helm search repo bitnami/mongo --versions
helm search repo bitnami/jupyterhub --versions
helm search repo fiware/trusted-issuers-list --versions
helm search repo bitnami/apisix --versions
```

### Install yq
The yq is a tool to analyze yaml files.
```
        wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin"
```
### Install jq
jq is a tool to analyze json files
```
  sudo apt-get install jq
```