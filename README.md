# Prometheus with node and kube exporters

This Kubernetes deployment uses [prometheus-operator](https://github.com/coreos/prometheus-operator) 
to deploy and configure [prometheus](https://prometheus.io/). It includes metrics exporters 
for kubenetes nodes, [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 
for metrics from the Kubernetes API, and [node-exporter](https://github.com/prometheus/node_exporter) 
for metrics from the Linux OS on each node. It also collects metrics from kube-dns and Prometheus.

This deployment is somewhat opinionated, but can be easily adapted.
- Expects you use a Kubernetes Ingress controller and basic authentication
- Expects you use [kube-cert-manager](https://github.com/whereisaaron/kube-cert-manager) to automatically issue Let's Encrypt SSL certificates (or you can do this manually)
- Expects to create domain names in AWS Route53 (or you can do this manually)

## Scripts

The deployment creates a namespace (if it does not exist) and almost all resources are created there.
Some ClusterRoles and and ClusterRoleBindings are created. The prometheus-operator creates
ThirdPartyResources is uses to configure Prometheus.

- Deploy.sh
- Display.sh
- Delete.sh

Before using the `Deploy.sh` script you should:
- Copy the '-example' file in 'prometheus-alerts' to create your local alerts configuration
- Check the persistent storage settings in 'promethes-operator-config/*.yaml' files
- Create a [basic auth secret](https://github.com/kubernetes/contrib/tree/master/ingress/controllers/nginx/examples/auth) or comment it out of 'prometheus-ingress/*.yaml'
- Define these environment variables
  - `DEPLOY_NAMESPACE` (defaults to 'prometheus')
  - `DEPLOY_PROMETHEUS_DOMAIN`
  - `DEPLOY_ALERTMANAGER_DOMAIN`
  - `DEPLOY_ACME_CLASS` if using [`kube-cert-manager`](https://github.com/whereisaaron/kube-cert-manager)
  - `DEPLOY_BASIC_AUTH_SECRET_NAME`
- Define `DEPLOY_AWS_ROUTE53_PROFILE` and `DEPLOY_INGRESS_DOMAIN` if you have [`cli53`](https://github.com/barnybug/cli53) or comment out

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
- kube-cert-manager
  - https://github.com/whereisaaron/kube-cert-manager
- cli53
  - https://github.com/barnybug/cli53

## Sample deployment

After running `./Deploy.sh`, `./Display.sh` will show resources similar to below.

```
---- Deploy namespace 'prometheus' ----

NAME               HOSTS                      ADDRESS            PORTS     AGE
ing/alertmanager   alertmanager.example.com   172.31.147.10...   80, 443   17h
ing/prometheus     prometheus.example.com     172.31.147.10...   80, 443   17h

NAME                        CLUSTER-IP   EXTERNAL-IP   PORT(S)             AGE
svc/alertmanager-main       10.30.0.28   <none>        9093/TCP            10m
svc/alertmanager-operated   None         <none>        9093/TCP,6783/TCP   9m
svc/kube-state-metrics      10.30.0.27   <none>        8080/TCP            10m
svc/node-exporter           None         <none>        9100/TCP            11m
svc/prometheus-main         10.30.0.29   <none>        9090/TCP            10m
svc/prometheus-operated     None         <none>        9090/TCP            9m

NAME                       ENDPOINTS                                                              AGE
ep/alertmanager-main       10.20.62.219:9093                                                      10m
ep/alertmanager-operated   10.20.62.219:9093,10.20.62.219:6783                                    9m
ep/kube-state-metrics      10.20.62.217:8080                                                      10m
ep/node-exporter           172.23.146.7:9100,172.23.147.108:9100,172.23.147.36:9100 + 3 more...   11m
ep/prometheus-main         10.20.7.182:9090                                                       10m
ep/prometheus-operated     10.20.7.182:9090                                                       9m

NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/kube-state-metrics    1         1         1            1           10m
deploy/prometheus-operator   1         1         1            1           10m

NAME               DESIRED   CURRENT   READY     NODE-SELECTOR   AGE
ds/node-exporter   6         6         6         <none>          11m

NAME                             DESIRED   CURRENT   AGE
statefulsets/alertmanager-main   1         1         9m
statefulsets/prometheus-main     1         1         9m

NAME                                      READY     STATUS    RESTARTS   AGE
po/alertmanager-main-0                    2/2       Running   0          9m
po/kube-state-metrics-2464863441-0lpwj    1/1       Running   0          10m
po/node-exporter-2gvxx                    1/1       Running   0          11m
po/node-exporter-c1jbm                    1/1       Running   0          11m
po/node-exporter-f7l5g                    1/1       Running   0          11m
po/node-exporter-hctfs                    1/1       Running   0          11m
po/node-exporter-sdvtp                    1/1       Running   0          11m
po/node-exporter-tr6np                    1/1       Running   0          11m
po/prometheus-main-0                      2/2       Running   0          9m
po/prometheus-operator-4173050914-50bjc   1/1       Running   0          10m

NAME                     SECRETS   AGE
sa/default               1         3d
sa/kube-state-metrics    1         10m
sa/prometheus            1         10m
sa/prometheus-operator   1         10m

NAME                       DATA      AGE
cm/alertmanager-main       1         10m
cm/prometheus-main         1         9m
cm/prometheus-main-rules   3         10m

NAME                                         TYPE                                  DATA      AGE
secrets/alertmanager.example.com             kubernetes.io/tls                     2         10m
secrets/default-token-zznjv                  kubernetes.io/service-account-token   3         3d
secrets/developers-basic-auth                Opaque                                1         2d
secrets/kube-state-metrics-token-x67s1       kubernetes.io/service-account-token   3         10m
secrets/prometheus-operator-token-0jwzx      kubernetes.io/service-account-token   3         10m
secrets/prometheus-token-q0pqp               kubernetes.io/service-account-token   3         10m
secrets/prometheus.beehive.example.com       kubernetes.io/tls                     2         10m

NAME                                           STATUS    VOLUME                                     CAPACITY   ACCESSMODES   AGE
pvc/alertmanager-main-db-alertmanager-main-0   Bound     pvc-30568797-f9f9-11e6-aa1f-06caefa32cf7   10Gi       RWO           2d
pvc/prometheus-main-db-prometheus-main-0       Bound     pvc-2c97accc-f9f9-11e6-aa1f-06caefa32cf7   40Gi       RWO           2d

---- Prometheus Operator configuration ----

NAME                KIND
prometheuses/main   Prometheus.v1alpha1.monitoring.coreos.com

NAME                                 KIND
servicemonitors/kube-dns             ServiceMonitor.v1alpha1.monitoring.coreos.com
servicemonitors/kube-state-metrics   ServiceMonitor.v1alpha1.monitoring.coreos.com
servicemonitors/node-exporter        ServiceMonitor.v1alpha1.monitoring.coreos.com
servicemonitors/prometheus           ServiceMonitor.v1alpha1.monitoring.coreos.com

NAME                 KIND
alertmanagers/main   Alertmanager.v1alpha1.monitoring.coreos.com

---- Extra Services to discover metrics endpoints ----

NAMESPACE     NAME               CLUSTER-IP   EXTERNAL-IP   PORT(S)     AGE
kube-system   kube-dns-metrics   None         <none>        10055/TCP   10m

---- Cluster permissions ----

NAME                               AGE
clusterroles/prometheus            10m
clusterroles/prometheus-operator   10m

NAME                                      AGE
clusterrolebindings/prometheus            10m
clusterrolebindings/prometheus-operator   10m

---- Third party resources ----

NAME                                    DESCRIPTION                           VERSION(S)
prometheus.monitoring.coreos.com        Managed Prometheus server             v1alpha1
service-monitor.monitoring.coreos.com   Prometheus monitoring for a service   v1alpha1
alertmanager.monitoring.coreos.com      Managed Alertmanager cluster          v1alpha1
```

## Sample use of Deploy.sh

```
Creating record in zone 'example.com'
Created record: 'prometheus.example. 3600 IN CNAME ingress.examaple.com.'
Creating record in zone 'example.com'
Created record: 'alertmanager.example.com. 3600 IN CNAME ingress.example.com.'
Deploying to namespace 'prometheus'
service "node-exporter" created
daemonset "node-exporter" created
service "kube-state-metrics" created
deployment "kube-state-metrics" created
clusterrolebinding "kube-state-metrics" created
clusterrole "kube-state-metrics" created
serviceaccount "kube-state-metrics" created
service "kube-dns-metrics" created
clusterrolebinding "prometheus" created
clusterrole "prometheus" created
serviceaccount "prometheus" created
clusterrolebinding "prometheus-operator" created
clusterrole "prometheus-operator" created
serviceaccount "prometheus-operator" created
deployment "prometheus-operator" created
configmap "alertmanager-main" created
configmap "prometheus-main-rules" created
ingress "alertmanager" created
service "alertmanager-main" created
ingress "prometheus" created
service "prometheus-main" created
Waiting for Operator to register third party objects...done.
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "main" not found
alertmanager "main" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "kube-dns" not found
servicemonitor "kube-dns" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "kube-state-metrics" not found
servicemonitor "kube-state-metrics" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "node-exporter" not found
servicemonitor "node-exporter" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "prometheus" not found
servicemonitor "prometheus" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "main" not found
prometheus "main" created
Done.
```

## Sample use of Delete.sh

```
Deleting record in zone 'example.com'
Warning: no records matched - nothing deleted
Deleting record in zone 'example.com'
Warning: no records matched - nothing deleted
alertmanager "main" deleted
servicemonitor "kube-dns" deleted
servicemonitor "kube-state-metrics" deleted
servicemonitor "node-exporter" deleted
servicemonitor "prometheus" deleted
prometheus "main" deleted
Giving Prometheus Operator 10s to clean up...
configmap "alertmanager-main" deleted
ingress "alertmanager" deleted
service "alertmanager-main" deleted
ingress "prometheus" deleted
service "prometheus-main" deleted
clusterrolebinding "prometheus" deleted
clusterrole "prometheus" deleted
serviceaccount "prometheus" deleted
clusterrolebinding "prometheus-operator" deleted
clusterrole "prometheus-operator" deleted
serviceaccount "prometheus-operator" deleted
deployment "prometheus-operator" deleted
service "node-exporter" deleted
daemonset "node-exporter" deleted
service "kube-state-metrics" deleted
deployment "kube-state-metrics" deleted
clusterrolebinding "kube-state-metrics" deleted
clusterrole "kube-state-metrics" deleted
serviceaccount "kube-state-metrics" deleted
service "kube-dns-metrics" deleted
service "prometheus-operated" deleted
service "alertmanager-operated" deleted
Not deleting namespace
thirdpartyresource "prometheus.monitoring.coreos.com" deleted
thirdpartyresource "service-monitor.monitoring.coreos.com" deleted
thirdpartyresource "alertmanager.monitoring.coreos.com" deleted
Done.
```
