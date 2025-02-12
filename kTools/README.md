# k8s Tools

- [k8s Tools](#k8s-tools)
  - [Component's definition](#components-definition)
  - [Renew the ingress certificate in minikube ingress](#renew-the-ingress-certificate-in-minikube-ingress)
  - [Log requests made to ingress](#log-requests-made-to-ingress)
- [Create a Minimum Viable component for quick testing](#create-a-minimum-viable-component-for-quick-testing)
  - [Deploy a web server](#deploy-a-web-server)
  - [Deploy a job](#deploy-a-job)

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
## Renew the ingress certificate in minikube ingress
  ```shell
  1- minikube addons configure ingress 
  # Enter the name of the tls certificate
  2- minikube addons disable ingress
  2- minikube addons enable ingress
  ```
- To generate a Lets encrypt certificate, follow the [guide LetsEncrypt Certificate generation](README-letsEncryptCertGeneration.md)

## Log requests made to ingress
The logs of your Ingress controller can be seen when it handles requests and returns errors such as "502 Bad Gateway".  
The Ingress infrastructure is held at a devoted namespace that can be named  _ingress-nginx_, _ingress_, ... depending on the kubernetes deployed.

```shell
# Identify the Ingress Controller Pods
$ kubectl get pods -n ingress-nginx
# Identify the name of your controller pod
$ kubectl logs <nginx-controller-pod-name> -n ingress-nginx
```

# Create a Minimum Viable component for quick testing
## Deploy a web server
When a recipy is provided to deploy a docker, the equivalent recipy for kubernetes would be something similar to:
1- In case the component provides a service (server) and has to be left alive.
The provided example has to be customized.  
```shell
# Equivalent to deploy something like docker run --name echo -d gcr.io/kubernetes-e2e-test-images/echoserver:2.2
K8S_COMPONENT_FILENAME=echo.yaml
K8S_COMPONENT_NAME=echo
K8S_COMPONENT_IMAGE=gcr.io/kubernetes-e2e-test-images/echoserver:2.2
K8S_COMPONENT_NAMESPACE=test
K8S_COMPONENT_EXTERNALPORT=8081
K8S_COMPONENT_INNERPORT=8080
K8S_COMPONENT_DNS=echo.local

# Creates the k8s_component's file
cat <<EOF > $K8S_COMPONENT_FILENAME
apiVersion: v1
kind: List
metadata:
  resourceVersion: ""
items:
  - apiVersion: v1
    kind: Namespace
    metadata:
      labels:
        kubernetes.io/metadata.name: ${K8S_COMPONENT_NAME}
        name: ${K8S_COMPONENT_NAME}
      name: $K8S_COMPONENT_NAMESPACE
  - apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: ${K8S_COMPONENT_NAME}
      name: ${K8S_COMPONENT_NAME}-svc
      namespace: $K8S_COMPONENT_NAMESPACE
    spec:
      ports:
        - port: $K8S_COMPONENT_INNERPORT
          protocol: TCP
          targetPort: $K8S_COMPONENT_INNERPORT
      selector:
        app: ${K8S_COMPONENT_NAME}

  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: ${K8S_COMPONENT_NAME}
      name: ${K8S_COMPONENT_NAME}-dp
      namespace: $K8S_COMPONENT_NAMESPACE
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: ${K8S_COMPONENT_NAME}
      template:
        metadata:
          creationTimestamp: null
          labels:
            app: ${K8S_COMPONENT_NAME}
        spec:
          containers:
            - image: $K8S_COMPONENT_IMAGE
              name: ${K8S_COMPONENT_NAME}
              ports:
                - containerPort: $K8S_COMPONENT_INNERPORT
              env:
                - name: NODE_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: spec.nodeName
                - name: POD_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.name
                - name: POD_NAMESPACE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.namespace
                - name: POD_IP
                  valueFrom:
                    fieldRef:
                      fieldPath: status.podIP
              resources: {}
  # - kind: Ingress
  #   apiVersion: networking.k8s.io/v1
  #   metadata:
  #     generation: 1
  #     name: echo-ingress
  #     namespace: test
  #   spec:
  #     ingressClassName: nginx
  #     rules:
  #       - host: $K8S_COMPONENT_DNS
  #         http:
  #           paths:
  #             - backend:
  #                 service:
  #                   name: echo-svc
  #                   port:
  #                     number: 8080
  #               path: /
  #               pathType: Prefix
  #     tls:
  #       - hosts:
  #           - K8S_COMPONENT_DNS
  #         secretName: K8S_COMPONENT_DNS-tls
EOF

kubectl apply  -f $K8S_COMPONENT_FILENAME
# If ingress is used and the DNS is global or locally registered at the /etc/hosts file you can try
curl -k https://$K8S_COMPONENT_DNS/

# Expose the pod to the host just for a quick test (if no ingress has been installed)
kubectl port-forward  --address 0.0.0.0  -n $K8S_COMPONENT_NAMESPACE svc/${K8S_COMPONENT_NAME}-svc $K8S_COMPONENT_EXTERNALPORT:$K8S_COMPONENT_INNERPORT 
# Test the access to the pod
curl http://127.0.0.1:${K8S_COMPONENT_EXTERNALPORT}/

# Delete the component
kubectl delete -f $K8S_COMPONENT_FILENAME
```

## Deploy a job
In case the component has to run just one action and exit.
The provided example has to be customized.  
```shell
# docker run -v $CERT_FOLDER:/cert -e STORE_PASS=hello quay.io/wi_stefan/did-helper:0.1.1 > /dev/null 2>&1
K8S_COMPONENT_FILENAME=job-generatedid.yaml
K8S_TYPE=Job
K8S_COMPONENT_NAME=job-generatedid
K8S_COMPONENT_IMAGE=quay.io/wi_stefan/did-helper:0.1.1
CERT_FOLDER=/tmp
cat <<EOF > $K8S_COMPONENT_FILENAME
apiVersion: batch/v1
kind: $K8S_TYPE
metadata:
  name: $K8S_COMPONENT_NAME
spec:
  ttlSecondsAfterFinished: 15
  backoffLimit: 0
  template:
    spec:
      containers:
      - name: $K8S_COMPONENT_NAME
        image: $K8S_COMPONENT_IMAGE
        volumeMounts:
        - mountPath: /cert
          name: tmp-volume
        env:
        - name: STORE_PASS
          value: hello
      restartPolicy: Never
      volumes:
      - name: tmp-volume
        hostPath:
          path: $CERT_FOLDER
          type: Directory
EOF

kubectl apply -f $K8S_COMPONENT_FILENAME
kubectl wait --for=condition=complete --timeout=300s job/$K8S_COMPONENT_NAME
```