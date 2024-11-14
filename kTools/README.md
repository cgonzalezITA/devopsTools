# k8s Tools

- [k8s Tools](#k8s-tools)
  - [Component's definition](#components-definition)
  - [k8s tips](#k8s-tips)
    - [Renew the ingress certificate in minikube ingress](#renew-the-ingress-certificate-in-minikube-ingress)
    - [Log requests made to ingress](#log-requests-made-to-ingress)

This folder contains scripts to ease certain operations on the kubernetes cluster.
These commands rely on the kubectl program to perform its functionality and has been tested in a Ubuntu 20.04.6 LTS.    

## Component's definition
This folder contains yaml files with the definition of components that could be used as tools once deployed in a namespace:  
- **k8s_components-utils.yaml**: Contains some utilities:
  - **netutils**: results in a pod with tools like nslookup, curl, wget, ping, ... installed.
  - **echo**: results in a pod that expose several server informations.    

To deploy them:
```shell
kubectl apply -n <targetNS> -f "kTools/<k8s_file. eg. k8s_components-utils>.yaml"
```
## k8s tips
### Renew the ingress certificate in minikube ingress
  ```shell
  1- minikube addons configure ingress 
  # Enter the name of the tls certificate
  2- minikube addons disable ingress
  2- minikube addons enable ingress
  ```
- To generate a Lets encrypt certificate, follow the [guide LetsEncrypt Certificate generation](README-letsEncryptCertGeneration.md)

### Log requests made to ingress
The logs of your Ingress controller can be seen when it handles requests and returns errors such as "502 Bad Gateway".  
```shell
# Identify the Ingress Controller Pods
$ kubectl get pods -n ingress-nginx
# Identify the name of your controller pod
$ kubectl logs <nginx-controller-pod-name> -n ingress-nginx
```