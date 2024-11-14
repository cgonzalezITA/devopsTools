# K8s components to get a let's encrypt certificate generated 
- [K8s components to get a let's encrypt certificate generated](#k8s-components-to-get-a-lets-encrypt-certificate-generated)
  - [Method 1](#method-1)
  - [Method 2](#method-2)
    - [Generation](#generation)
    - [Verification](#verification)
    - [Other operations](#other-operations)
      - [Extract the certificate and the private key](#extract-the-certificate-and-the-private-key)
      - [Generate a cert.pfx file](#generate-a-certpfx-file)
      - [Clean the resources used](#clean-the-resources-used)
    - [Errors during verification](#errors-during-verification)


Based on the description done at 
https://dev.to/ileriayo/adding-free-ssltls-on-kubernetes-using-certmanager-and-letsencrypt-a1l  
Let's Encrypt is a nonprofit Certificate Authority that provides TLS certificates to 300 million websites.  
Cert-manager is a native Kubernetes certificate management controller.   
It can help with issuing certificates from a variety of sources, such as Let's Encrypt, HashiCorp Vault, Venafi, 
a simple signing key pair, or self signed.  
- [Method 1 (older)](#method-1)
- [Method 2 with Helm)](#method-2)
## Method 1
STEPS:  
1- Execute  
>   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.1.1/cert-manager.yaml  

2- Verify deployment at namespace cert-manager  
>   kubectl get pods -n cert-manager
> 
3- Create the clusterIssuer manifest 
The **secret-fiwaredsc-ita.es** string must be updated to match the certificate name to be generated.  
```shell
CLUSTERISSUER_YAML_FILE=clusterIssuer.yaml
echo "apiVersion: cert-manager.io/v1                            " >  $CLUSTERISSUER_YAML_FILE
echo "kind: ClusterIssuer # I'm using ClusterIssuer here        " >> $CLUSTERISSUER_YAML_FILE
echo "metadata:                                                 " >> $CLUSTERISSUER_YAML_FILE
echo "  name: secret-fiwaredsc-ita.es                           " >> $CLUSTERISSUER_YAML_FILE
echo "spec:                                                     " >> $CLUSTERISSUER_YAML_FILE
echo "  acme:                                                   " >> $CLUSTERISSUER_YAML_FILE
echo "    server: https://acme-v02.api.letsencrypt.org/directory" >> $CLUSTERISSUER_YAML_FILE
echo "    email: cgonzalez@ita.es                               " >> $CLUSTERISSUER_YAML_FILE
echo "    privateKeySecretRef:                                  " >> $CLUSTERISSUER_YAML_FILE
echo "      name: secret-fiwaredsc-ita.es                       " >> $CLUSTERISSUER_YAML_FILE
echo "    solvers:                                              " >> $CLUSTERISSUER_YAML_FILE
echo "    - http01:                                             " >> $CLUSTERISSUER_YAML_FILE
echo "        ingress:                                          " >> $CLUSTERISSUER_YAML_FILE
echo "          class: traefik                                  " >> $CLUSTERISSUER_YAML_FILE
```
4- Apply it  
> kubectl apply -f $CLUSTERISSUER_YAML_FILE


5- Create or update ingress using the following annotation:  
```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
...
    annotations:
      cert-manager.io/cluster-issuer: secret-fiwaredsc-ita.es
...
    tls:
    - hosts:
      - # your domain 
      secretName: secret-fiwaredsc-ita.es # secret name, same as the privateKeySecretRef in the (Cluster)Issuer
```
For example:
```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    labels:
      app: hello-world
    name: 
    namespace: <namespace> # if non-default namespace
    annotations:
      cert-manager.io/cluster-issuer: secret-fiwaredsc-ita.es
  spec:
    rules:
    - host: example.com # your domain
      http:
        paths:
        - backend:
            service:
              name: <your-service>
              port:
                number: 80 # use appropriate port
          path: /
          pathType: Prefix
    tls:
    - hosts:
      - example.com # your domain 
      secretName: secret-fiwaredsc-ita.es # secret name, same as the privateKeySecretRef in the (Cluster)Issuer
```

6- Once deployed, the ingress must have triggered the generation of the new certificate or its update. You can verify that a certificate has been issued  
> kubectl -n <namespace> describe certificate secret-fiwaredsc-ita.es

7- To extract the generated files:  
> kubectl get secret secret.ita.es-tls -o json | jq -r '.data."tls.crt"' | base64 -d  

7.1- Extract the public key (fullchain.pem)  
> kubectl get secret secret.ita.es-tls -o json | jq -r '.data."tls.crt"' | base64 -d

7.2- Extract the priv key (tls.key; privkey.pem)
> kubectl get secret secret.ita.es-tls -o json | jq -r '.data."tls.crt"' | base64 -d  

8- Delete the stuff  
> rm $CLUSTERISSUER_YAML_FILE


## Method 2
STEPS:  
### Generation
1- Deploy the cert-manager (via helm)
```shell
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version vX.Y.Z --set installCRDs=true
X.Y.Z can be taken from https://artifacthub.io/packages/helm/cert-manager/cert-manager (latest on 240909: v1.15.3)
```

2- Generate the yaml with the clusterissuer and the certificate  
These components generate a let's encrypt certificate for the given 'dnsNames:'
[How to solve problems](https://cert-manager.io/docs/troubleshooting/)
```shell
  (  +---------+  )
  (  | Ingress |  ) Optional                                   |  ACME Only! 
  (  +---------+  )                                            |
         |                                                     |
         |   +-------------+      +--------------------+       |  +-------+       +-----------+
         |-> | Certificate |----> | CertificateRequest | ----> |  | Order | ----> | Challenge |
             +-------------+      +--------------------+       |  +-------+       +-----------+
                                                               |
```

Interesting links:
- https://stackoverflow.com/questions/63346728/issuing-certificate-as-secret-does-not-exist

Shell commands to generate the yaml file with the clusterIssuer and the certificate definitions:  
```shell
#TB Customized: CLUSTERISSUER_YAML_FILE
CLUSTERISSUER_YAML_FILE=clusterIssuer_and_certificate.yaml

#TB Customized: DNS
DNS=fdsc-consumer-keycloak.ita.es

#TB Customized: EMAIL
# You must replace this email address with your own.       
# Let's Encrypt will use this to contact you about expiring
# certificates, and issues related to your account.        
EMAIL=cgonzalez@ita.es

cat <<EOF > $CLUSTERISSUER_YAML_FILE
apiVersion: v1                                                                 
kind: Namespace                                                                
metadata:                                                                      
  name: ns-certs-generation                                                      
---                                                                            
apiVersion: cert-manager.io/v1                                                 
kind: ClusterIssuer                                                            
metadata:                                                                      
  name: letsencrypt-issuer-prod                                                
  namespace: ns-certs-generation                                                 
spec:                                                                          
  acme:                                                                        
    email: $EMAIL
    # server: https://acme-staging-v02.api.letsencrypt.org/directory           
    # server: https://acme-v02.api.letsencrypt.org/directory                   
    server: https://acme-staging-v02.api.letsencrypt.org/directory             
    privateKeySecretRef:                                                       
      # Secret resource that will be used to store the account's private key.  
      # This is your identity with your ACME provider. If you lose this        
      # identity/secret, you will be able to generate a new one and generate   
      # certificates for any/all domains managed using your previous account,  
      # but you will be unable to revoke any certificates generated using that 
      # previous account.                                                      
      # name: example-issuer-account-key                                       
      name: letsencrypt-staging                                                
    # Add a single challenge solver, HTTP01 using nginx                        
    solvers:                                                                   
      # - dns01:                                                               
      #     webhook:                                                           
      #       groupName: acme.scaleway.com                                     
      #       solverName: scaleway                                             
      - http01:                                                                
          ingress:                                                             
            ingressClassName: nginx                                            
---                                                                            
apiVersion: cert-manager.io/v1                                                 
kind: Certificate                                                              
metadata:                                                                      
  name: letsencrypt-cert                                                       
  namespace: ns-certs-generation                                                 
spec:                                                                          
  commonName: $DNS                                                             
  dnsNames:                                                                    
    - $DNS                                                                  
  secretName: letsencrypt-cert-tls                                             
  issuerRef:                                                                   
    name: letsencrypt-issuer-prod   
    kind: ClusterIssuer                                           
EOF
```

3- Deploy clusterissuer and the certificate to start the ACME certificate generation (port 80 must be accessible from outside your organization)
> kubectl apply -f $CLUSTERISSUER_YAML_FILE

### Verification
4- Check the status of the certificate
```shell
kubectl -n ns-certs-generation get certs
# or
kGet -a certs -n ns-certs
NAMESPACE             NAME               READY      SECRET                 AGE
ns-certs-generation   letsencrypt-cert   TRUE|FALSE letsencrypt-cert-tls   13s
```
The READY shows the status of the cert. It can be TRUE (success) or FALSE (error)

4.1- View the details of the certificate
```shell
kubectl describe -n ns-certs-generation certs  letsencrypt-cert
# or
kDescribe -a certs -n ns cert
# The output should contain a reference of a CertificateRequest artifact just created to generate the certificate:
Events:
  Type    Reason     Age   From                                       Message
  ----    ------     ----  ----                                       -------
  Normal  Issuing    35s   cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  35s   cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "letsencrypt-cert-rqdqw"
  Normal  Requested  35s   cert-manager-certificates-request-manager  Created new CertificateRequest resource "letsencrypt-cert-1"
```

4.2- Check the details of the just created CertificateRequest:
```shell
kubectl describe -n ns-certs-generation CertificateRequest letsencrypt-cert-1
    # The sucessful generation should generate an output similar to:
    # ...
    #   Conditions:
    #     Last Transition Time:  2024-09-10T11:46:49Z
    #     Message:               Certificate request has been approved by cert-manager.io
    #     Reason:                cert-manager.io
    #     Status:                True
    #     Type:                  Approved
    #     Message:               Certificate fetched from issuer successfully
    #     Reason:                Issued
    #     Status:                True
    #     Type:                  Ready
```

5- Once the cert has been generated, the letsencrypt-cert-tls secret (specified at the certificate) should be available
```shell
kubectl get secret  -n ns-certs-generation
# or
kGet  -n ns-certs-generation secrets letsencrypt-cert-tls

#To extract its content, use the kSecret-show command. eg:
kSecret-show -n ns tls
#   K8S_SECRETNAME=[tls] -> [letsencrypt-cert-tls]
#   BASE64 encoding used=[true]
#   NAMESPACE=[ns] -> [ns-certs-generation]
# ---
# Found [2] keys in the section [data] of the secret [letsencrypt-cert-tls]:
#         ["tls.crt" "tls.key" ]
# 1/2- Do you want to get value of key ["tls.crt"] (base64=true) [Y/n]? 
    # ---
    # - name:  "tls.crt"
    #   value:  -----BEGIN CERTIFICATE-----
    # ...
    # -----END CERTIFICATE-----
    # -----BEGIN CERTIFICATE-----
    # ...
    # ...
    # -----END CERTIFICATE-----
    # -  INFO of CER ["tls.crt"]:
    #   subject=CN = fdsc-consumer-keycloak.ita.es
    #   dates:
    #     notBefore=Sep 10 10:48:44 2024 GMT
    #     notAfter=Dec  9 10:48:43 2024 GMT
    #   issuer=
    #     countryName=US
    #     organizationName=(STAGING) Let's Encrypt
    #     commonName=(STAGING) Wannabe Watercress R11
    # ---
    # 2/2- Do you want to get value of key ["tls.key"] (base64=true) [Y/n]? 
    # ---
    # - name:  "tls.key"
    #   value:  -----BEGIN RSA PRIVATE KEY-----
    # ...
    # -----END RSA PRIVATE KEY-----
    # ---
```

### Other operations  
#### Extract the certificate and the private key
```shell
kubectl get secret cert-tls-fdsc-consumer-keycloak.ita.es -n ns-certs-generation -o jsonpath='{.data.tls\.crt}' | base64 --decode > tls.crt
# or
kSecret-show -n ns-certs-generation cert-tls-fdsc-consumer-keycloak.ita.es > tls.crt (Answering Y and N to pickup just the tls.crt piece)


kubectl get secret cert-tls-fdsc-consumer-keycloak.ita.es -n ns-certs-generation -o jsonpath='{.data.tls\.key}' | base64 --decode > c
tls.key
# or
kSecret-show -n ns-certs-generation cert-tls-fdsc-consumer-keycloak.ita.es > tls.key (Answering N and Y to pickup just the tls.key piece)

# The generated files have to be cleated to contain just the public (tls.crt) and the private (tls.key) files:
# > tls.crt: Should be cleaned to keep the content from the first -----BEGIN CERTIFICATE----- to the last -----END CERTIFICATE----- with a final end line
# > tls.key: Should be cleaned to keep the content from the first -----BEGIN RSA PRIVATE KEY----- to the last -----END RSA PRIVATE KEY----- with a final end line
```
#### Generate a cert.pfx file
```shell
openssl pkcs12 -export -out cert.pfx -inkey tls.key -in tls.crt
```

#### Clean the resources used
WARNING. This step will remove the generated secret!!!!
Once you are fully sure you want to get rid of everything, you can proceed with the destruction:
```shell
kubectl delete -f $CLUSTERISSUER_YAML_FILE
helm uninstall cert-manager
```

### Errors during verification
7- The status (STATE) of the cert returns FALSE
7.1 State: invalid (probably due to port 80 closed)  
> **Reason**: Error accepting authorization: acme: authorization error for fiwaredsc.ita.es: 400 urn:ietf:params:acme:error:connection: 193.144.226.88: Fetching http://fiwaredsc.ita.es/.well-known/acme-challenge/ooUssanKwmqzGOYloqd6Hmr0EPxqutLkCcDyvxj7cEU: Timeout during connect (likely firewall problem)  

7.2 State: invalid (probably due to host not reachable, not globaly accessible or does not exist)  
> **Reason**: Waiting for HTTP-01 challenge propagation: failed to perform self check GET request 'http://fiwaredscaaa.ita.es/.well-known/acme-challenge/Xo-hbS0lpiZWNDJh5HBov1H6V_hwHtNOBaNpQJp-eGI': Get "http://fiwaredscaaa.ita.es/.well-known/acme-challenge/Xo-hbS0lpiZWNDJh5HBov1H6V_hwHtNOBaNpQJp-eGI": dial tcp: lookup fiwaredscaaa.ita.es on 10.96.0.10:53: no such host