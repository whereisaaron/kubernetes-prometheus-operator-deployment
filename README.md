# Prometheus with node and kube exporters

This deployment uses [prometheus-operator](https://github.com/coreos/prometheus-operator) 
to deploy and configure [prometheus](https://prometheus.io/). It includes metrics exporters 
for kubenetes nodes, [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 
for metrics from the kubernetes API, and [node-exporter](https://github.com/prometheus/node_exporter) 
for metrics from the Linux OS on each node.

## Scripts

The deployment creates a 'prometheus' namespace and all resources are created there.
Some ClusterRoles and and ClusterRoleBindings are created. The prometheus-operator creates
ThirdPartyResources is uses to configure Prometheus.

- Deploy.sh
- Display.sh
- Delete.sh

## Relevant Links

- Prometheus Operator
  - https://github.com/coreos/prometheus-operator
  - https://quay.io/repository/coreos/prometheus-operator
- Prometheous
  - https://github.com/prometheus/prometheus
  - https://quay.io/repository/prometheus/prometheus
- node-exporter
  - https://github.com/prometheus/node_exporter
  - https://quay.io/repository/prometheus/node-exporter
- kube-state-metrics
  - https://github.com/kubernetes/kube-state-metrics
  - curl https://gcr.io/v2/google_containers/kube-state-metrics/tags/list
- configmap-reload (sidecar to reload pometheus on config changes)
  - https://github.com/jimmidyson/configmap-reload
  - https://hub.docker.com/r/jimmidyson/configmap-reload/

## Sample deployment

```
---- Prometheus namespace ----

NAME                      CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
svc/kube-state-metrics    10.30.0.167   <none>        8080/TCP   11m
svc/node-exporter         None          <none>        9100/TCP   11m
svc/prometheus-operated   None          <none>        9090/TCP   10m

NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/kube-state-metrics    1         1         1            1           11m
deploy/prometheus-operator   1         1         1            1           11m

NAME               DESIRED   CURRENT   READY     NODE-SELECTOR   AGE
ds/node-exporter   6         6         6         <none>          11m

NAME                           DESIRED   CURRENT   AGE
statefulsets/prometheus-main   1         1         10m

NAME                                      READY     STATUS    RESTARTS   AGE
po/kube-state-metrics-2464863441-bbhd6    1/1       Running   0          11m
po/node-exporter-09rqm                    1/1       Running   0          11m
po/node-exporter-47n1h                    1/1       Running   0          11m
po/node-exporter-bnnlw                    1/1       Running   0          11m
po/node-exporter-mh7w8                    1/1       Running   0          11m
po/node-exporter-qqvc4                    1/1       Running   0          11m
po/node-exporter-v4qdr                    1/1       Running   0          11m
po/prometheus-main-0                      2/2       Running   0          10m
po/prometheus-operator-4173050914-6qdwz   1/1       Running   0          11m

NAME                     SECRETS   AGE
sa/default               1         5h
sa/kube-state-metrics    1         11m
sa/prometheus            1         11m
sa/prometheus-operator   1         11m

NAME                       DATA      AGE
cm/prometheus-main         1         10m
cm/prometheus-main-rules   0         10m

---- Prometheus Operator configuration ----

NAME                KIND
prometheuses/main   Prometheus.v1alpha1.monitoring.coreos.com

NAME                                 KIND
servicemonitors/kube-state-metrics   ServiceMonitor.v1alpha1.monitoring.coreos.com
servicemonitors/node-exporter        ServiceMonitor.v1alpha1.monitoring.coreos.com

---- Cluster permissions ----

NAME                               AGE
clusterroles/prometheus            11m
clusterroles/prometheus-operator   11m

NAME                                      AGE
clusterrolebindings/prometheus            11m
clusterrolebindings/prometheus-operator   11m

---- Third party resources ----

NAME                                    DESCRIPTION                           VERSION(S)
prometheus.monitoring.coreos.com        Managed Prometheus server             v1alpha1
service-monitor.monitoring.coreos.com   Prometheus monitoring for a service   v1alpha1
alertmanager.monitoring.coreos.com      Managed Alertmanager cluster          v1alpha1
```
