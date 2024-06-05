# Deploy cert-manager
K8ssandra Operator has a dependency on cert-manager, which must be installed in each cluster, if not already available.

## Automate SSL Encryption with Cert-Manager
- Create a new private key and certificate pair for your root CA.
```
openssl genrsa -out cert/tls.key 4096
openssl req -new -x509 -key cert/tls.key -out ./tls.crt -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Global Security/OU=DevOps Department/CN=example.com"
```

- Create a Kubernetes secret for the Root CA
```
k -n k8ssandra-operator create secret tls cass-demo-ca --key certs/tls.key --cert certs/tls.crt 
```

- Create a cert-manager Issuer resource. It will use our Issuer to generate JKS Keystore for Cassandra
```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cass-demo-ca-issuer
  namespace: k8ssandra-operator
spec:
  ca:
    secretName: cass-demo-ca
```
- Create a cert-manager Certificate resource. It will use our Root CA
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cass-cert
  namespace: k8ssandra-operator
spec:
  secretName: cassandra-jks-keystore
  issuerRef:
    name: cass-demo-ca-issuer
    kind: Issuer
  usages:
    - server auth
    - client auth
  keystores:
    jks:
      create: true
      passwordSecretRef:
        name: keystore-pass
        key: password
  dnsNames:
    - dc1.k8ssandra-operator.svc.cluster.local     
```
Some explaintaions for the Certificate spec:
- The keystore, truststore and certificates will be fields within a secret called `cassandra-jks-keystore`. This secret will end up holding our KS PSK and KS PC.
- It has a DNS name – you could also provide a URI or IP address. In this case we have used the **service address** of the Cassandra datacenter created the operator. This has a format of `DC_NAME.NAMESPACE.svc.cluster.local`
--> Need to verify, not entirely correct in real setup. Should be `CLUSTER_NAME-DC_NAME-service.NAMESPACE.svc.cluster.local`
```
$ kgs  
NAME                                               TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                 AGE
cluster1-dc1-additional-seed-service               ClusterIP   None          <none>        <none>                                                  24m
cluster1-dc1-all-pods-service                      ClusterIP   None          <none>        9042/TCP,8080/TCP,9103/TCP,9000/TCP                     24m
cluster1-dc1-service                               ClusterIP   None          <none>        9042/TCP,9142/TCP,8080/TCP,9103/TCP,9000/TCP,9160/TCP   24m
cluster1-seed-service                              ClusterIP   None          <none>        <none>                                                  24m
```
Finally, create a generic Secret resource for your keystore password:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: keystore-pass
  namespace: k8ssandra-operator
type: Opaque
data:
  password: a2V5cGFzcw==
```
- Once completed, cert-manager will create the secret resource which contain the keystore.jks and truststore.jks for your Cassandra:
```yaml
$ kubectl describe secret cassandra-jks-keystore                 

Name:         cassandra-jks-keystore
Namespace:    k8ssandra-operator
Labels:       controller.cert-manager.io/fao=true
Annotations:  cert-manager.io/alt-names: dc1.k8ssandra-operator.svc.cluster.local
              cert-manager.io/certificate-name: cass-cert
              cert-manager.io/common-name: 
              cert-manager.io/ip-sans: 
              cert-manager.io/issuer-group: cert-manager.io
              cert-manager.io/issuer-kind: Issuer
              cert-manager.io/issuer-name: cass-demo-ca-issuer
              cert-manager.io/subject-organizations: datastax
              cert-manager.io/uri-sans: 

Type:  kubernetes.io/tls

Data
====
ca.crt:          2082 bytes
keystore.jks:    4061 bytes
tls.crt:         1659 bytes
tls.key:         1675 bytes
truststore.jks:  1553 bytes
```

## Deploy CassandraDatacenter

```yaml
apiVersion: cassandra.datastax.com/v1beta1
kind: CassandraDatacenter
metadata:
  name: dc1
spec:
  clusterName: cluster1
  serverType: cassandra
  serverVersion: 3.11.10
  managementApiAuth:
    insecure: {}
  size: 1
  podTemplateSpec:
    spec:
      containers:
        - name: "cassandra"
          volumeMounts:
          - name: certs
            mountPath: "/crypto"
      volumes:
      - name: certs
        secret:
          secretName: cassandra-jks-keystore
  storageConfig:
    cassandraDataVolumeClaimSpec:
      storageClassName: standard
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
  config:
    cassandra-yaml:
      authenticator: org.apache.cassandra.auth.AllowAllAuthenticator
      authorizer: org.apache.cassandra.auth.AllowAllAuthorizer
      role_manager: org.apache.cassandra.auth.CassandraRoleManager
      client_encryption_options:
        enabled: true
        # If enabled and optional is set to true encrypted and unencrypted connections are handled.
        optional: false
        keystore: /crypto/keystore.jks
        keystore_password: dc1
        require_client_auth: true
        # Set trustore and truststore_password if require_client_auth is true
        truststore: /crypto/truststore.jks
        truststore_password: dc1
        protocol: TLS
        # cipher_suites: [TLS_RSA_WITH_AES_128_CBC_SHA] # An earlier version of this manifest configured cipher suites but the proposed config was less secure. This section does not need to be modified.
      server_encryption_options:
        internode_encryption: all
        keystore: /crypto/keystore.jks
        keystore_password: dc1
        truststore: /crypto/truststore.jks
        truststore_password: dc1
    jvm-options:
      initial_heap_size: 800M
      max_heap_size: 800M
```