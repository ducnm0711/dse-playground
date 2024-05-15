# k8ssandra-operator

Kubernetes operator which handles the provisioning and management of K8ssandra clusters.

**Homepage:** <https://github.com/k8ssandra/k8ssandra-operator>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| K8ssandra Team | k8ssandra-developers@googlegroups.com | https://github.com/k8ssandra |

## Source Code

* <https://github.com/k8ssandra/k8ssandra-operator>
* <https://github.com/k8ssandra/k8ssandra/tree/main/charts/k8ssandra-operator>

## Requirements

| Repository | Name |
|------------|------|
| https://helm.k8ssandra.io | cass-operator |
| https://helm.k8ssandra.io | k8ssandra-common |

## Notes:
https://github.com/k8ssandra/cass-operator/issues/263

## Intall

helm install k8ssandra-operator k8ssandra/k8ssandra-operator -n k8ssandra-operator -f values.yaml
helm diff upgrade --install k8ssandra-operator k8ssandra/k8ssandra-operator -n k8ssandra-operator -f values.yaml

