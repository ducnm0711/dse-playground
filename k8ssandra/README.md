# Deploy cert-manager
K8ssandra Operator has a dependency on cert-manager, which must be installed in each cluster, if not already available.

# Deploy K8ssandra Operator 
You can deploy K8ssandra Operator for namespace-scoped operations (the default), or cluster-scoped operations.

Deploying a namespace-scoped K8ssandra Operator means its operations – watching for resources to deploy in Kubernetes – are specific only to the identified namespace within a cluster.
Deploying a cluster-scoped operator means its operations – again, watching for resources to deploy in Kubernetes – are global to all namespace(s) in the cluster. The example in this section shows K8ssandra Operator deployed as namespace scoped

## Deployment
Apache Cassandra can be deployed into multiple datacenters in separate regions or availability/failure zones. k8ssandra-operator makes this possible by enabling communication between multiple Kubernetes clusters and deploying Cassandra datacenters into them.

This distinguishes k8ssandra-operator from cass-operator (which is used internally within k8ssandra-operator) which does not automate multi-region deployments.

A single k8ssandra-operator instance in a control plane cluster can manage many data plane DCs across multiple Kubernetes clusters, and split across multiple Cassandra clusters. Clusters of up to 1000 nodes have been tested and confirmed to perform well.


## Telemetry (Metrics)

Revamped metrics endpoint
Since the very first version, K8ssandra has used MCAC to expose metrics in a Prometheus compliant format. 

While MCAC can work with Kubernetes, it wasn’t designed for it. Over the past couple years, we listed some inefficiencies and pain points which eventually led to a redesign.

Starting with v1.5.0, k8ssandra-operator will support deploying Vector agent as a sidecar to the Cassandra, Stargate and Reaper pods, preconfigured to scrape metrics from the available endpoints.

https://docs.k8ssandra.io/tasks/monitor/vector/#enabling-vector-agent

```yaml
apiVersion: k8ssandra.io/v1alpha1
kind: K8ssandraCluster
metadata:
  name: test
spec:
  cassandra:
    serverVersion: 4.1.4
    telemetry:
      vector:
        enabled: true
```
## Test Scenarios
https://github.com/k8ssandra/k8ssandra-operator/tree/main/test/testdata

## CRD:
https://github.com/k8ssandra/k8ssandra/blob/main/charts/cass-operator/crds/cassandradatacenters.yaml