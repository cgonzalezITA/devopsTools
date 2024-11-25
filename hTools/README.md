# hTools
This folder contains a set of scripts, documentation and yaml helm files to ease the helm chores.
## Index
- [hTools](#htools)
  - [Index](#index)
  - [Char templates](#char-templates)
    - [utils.yaml](#utilsyaml)
    - [secret-tls.yaml](#secret-tlsyaml)
  - [Helm Repo operations](#helm-repo-operations)
  - [Install yq](#install-yq)
  - [Install jq](#install-jq)
## Char templates
This section shows some templates that can be used in your own templates  
### utils.yaml
- The file [utils.yaml](./templates/utils.yaml) contains a set of tools can be copied into the template's helm folder of your helm chart.  
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
```yaml
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
        - path: /
```

Once deployed, the URL https://MyDNS.com/echo will show a set of server informations.

### secret-tls.yaml
- The file [secret-tls.yaml](./templates/secret-tls.yaml) Creates a tls secret thought to be used by your ingress tls to provide a https certificate
```
|<helmFolder>
 |- templates
   |- secret-tls.yaml
 |- certs
   |- tls.crt
   |- tls.key
 |- Chart.yaml
 |- values.yaml
```
The values file should contain something similar to
```yaml
tls:
  enabled: true
  name: <SECRETNAME>. # eg.mydns-tls
  crtFile: certs/tls.crt
  keyFile: certs/tls.key
```
REMEMBER: Create TLS Certificates (Transport Layer Security).  
- Using Organization official certificates (issued by Certification authority companies such as Let’s encrypt, ZeroSSL, …) For every public TLS/SSL certificate, CAs must verify, at a minimum, the requestors' domain.e.g. Let’s encrypt.  
- Generating not trusted certificates just for testing:  

    ```shell
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout <helmFolder>/certs/tls.key -out <helmFolder>/certs/tls.crt -subj "/CN=*.local"
    ```

## Helm Repo operations
```shell
# Add a new repo
# https://helm.sh/docs/helm/helm_repo_add/
helm repo add <repoName> <url>
  # Examples:
  # helm repo add bitnami https://charts.bitnami.com/bitnami

# View the names of the downloaded repos
helm repo list  
# Update the info of a repo
helm repo update <repo>
  # helm repo update bitnami
  
# List all the charts in a repo
# helm search repo <repoName> [<chartNameClue>]
  # Examples:
  # helm search repo fiware api
    # NAME                    CHART VERSION   APP VERSION     DESCRIPTION                                     
    # fiware/tm-forum-api     0.9.4           0.13.2          A Helm chart for running the FIWARE TMForum-APIs

# Search all the versions for a repo/chart
helm search repo <repoName>/<chartName> --versions  
  # Examples:
  # helm search repo bitnami/keycloak --versions
  # helm search repo bitnami/mongo --versions
  # helm search repo bitnami/jupyterhub --versions
  # helm search repo fiware/trusted-issuers-list --versions
  # helm search repo bitnami/apisix --versions
```

## Install yq
The yq is a tool to analyze yaml files.
```shell
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin"
```
## Install jq
jq is a tool to analyze json files
```shell
  sudo apt-get install jq
```