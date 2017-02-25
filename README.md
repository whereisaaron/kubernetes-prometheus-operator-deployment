# Prometheus with node and kube exporters

This Kubernetes deployment uses [prometheus-operator](https://github.com/coreos/prometheus-operator) 
to deploy and configure [prometheus](https://prometheus.io/). It includes metrics exporters 
for kubenetes nodes, [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 
for metrics from the Kubernetes API, and [node-exporter](https://github.com/prometheus/node_exporter) 
for metrics from the Linux OS on each node.

This deployment is somewhat opinionated, but can be easily adapted.
- All resources are deployed in a 'prometheus' namespace
- Expects you use a Kubernetes Ingress controller and basic authentication
- Expects you use [kube-cert-manager](https://github.com/whereisaaron/kube-cert-manager) to automatically issue Let's Encrypt SSL certificates (or you can do this manually)
- Expects to create domain names in AWS Route53 (or you can do this manually)

## Scripts

The deployment creates a 'prometheus' namespace and all resources are created there.
Some ClusterRoles and and ClusterRoleBindings are created. The prometheus-operator creates
ThirdPartyResources is uses to configure Prometheus.

- Deploy.sh
- Display.sh
- Delete.sh

Before using the `Deploy.sh` script you should:
- Copy the '-example' files in 'prometheus-alerts' to create your local alerts configuration
- Check the persistent storage settings in 'promethes-operator-config/*.yaml' files
- Create a [basic auth secret](https://github.com/kubernetes/contrib/tree/master/ingress/controllers/nginx/examples/auth) or comment it out of 'prometheus-ingress/*.yaml'
- Define these environment variables
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
---- Prometheus namespace ----

NAME               HOSTS                      ADDRESS            PORTS     AGE
ing/alertmanager   alertmanager.example.com   172.23.147.10...   80, 443   17h
ing/prometheus     prometheus.example.com     172.23.147.10...   80, 443   17h

NAME                        CLUSTER-IP    EXTERNAL-IP   PORT(S)             AGE
svc/alertmanager-main       10.30.0.127   <none>        9093/TCP            17h
svc/alertmanager-operated   None          <none>        9093/TCP,6783/TCP   1d
svc/kube-state-metrics      10.30.0.167   <none>        8080/TCP            1d
svc/node-exporter           None          <none>        9100/TCP            1d
svc/prometheus-main         10.30.0.47    <none>        9090/TCP            17h
svc/prometheus-operated     None          <none>        9090/TCP            1d

NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/kube-state-metrics    1         1         1            1           1d
deploy/prometheus-operator   1         1         1            1           1d

NAME               DESIRED   CURRENT   READY     NODE-SELECTOR   AGE
ds/node-exporter   6         6         6         <none>          1d

NAME                             DESIRED   CURRENT   AGE
statefulsets/alertmanager-main   1         1         1d
statefulsets/prometheus-main     1         1         1d

NAME                                      READY     STATUS    RESTARTS   AGE
po/alertmanager-main-0                    2/2       Running   0          16h
po/kube-state-metrics-2464863441-bbhd6    1/1       Running   0          1d
po/node-exporter-09rqm                    1/1       Running   0          1d
po/node-exporter-47n1h                    1/1       Running   0          1d
po/node-exporter-bnnlw                    1/1       Running   0          1d
po/node-exporter-mh7w8                    1/1       Running   0          1d
po/node-exporter-qqvc4                    1/1       Running   0          1d
po/node-exporter-v4qdr                    1/1       Running   0          1d
po/prometheus-main-0                      2/2       Running   0          16h
po/prometheus-operator-4173050914-6qdwz   1/1       Running   0          1d

NAME                     SECRETS   AGE
sa/default               1         2d
sa/kube-state-metrics    1         1d
sa/prometheus            1         1d
sa/prometheus-operator   1         1d

NAME                       DATA      AGE
cm/alertmanager-main       1         1d
cm/prometheus-main         1         1d
cm/prometheus-main-rules   1         1d

NAME                                         TYPE                                  DATA      AGE
secrets/alertmanager.example.com             kubernetes.io/tls                     2         17h
secrets/default-token-zznjv                  kubernetes.io/service-account-token   3         2d
secrets/developers-basic-auth                Opaque                                1         18h
secrets/kube-state-metrics-token-m90cd       kubernetes.io/service-account-token   3         1d
secrets/prometheus-operator-token-j52bn      kubernetes.io/service-account-token   3         1d
secrets/prometheus-token-3pn39               kubernetes.io/service-account-token   3         1d
secrets/prometheus.example.com               kubernetes.io/tls                     2         17h

NAME                                           STATUS    VOLUME                                     CAPACITY   ACCESSMODES   AGE
pvc/alertmanager-main-db-alertmanager-main-0   Bound     pvc-30568797-f9f9-11e6-aa1f-06caefa32cf7   10Gi       RWO           1d
pvc/prometheus-main-db-prometheus-main-0       Bound     pvc-2c97accc-f9f9-11e6-aa1f-06caefa32cf7   40Gi       RWO           1d

---- Prometheus Operator configuration ----

NAME                KIND
prometheuses/main   Prometheus.v1alpha1.monitoring.coreos.com

NAME                                 KIND
servicemonitors/kube-state-metrics   ServiceMonitor.v1alpha1.monitoring.coreos.com
servicemonitors/node-exporter        ServiceMonitor.v1alpha1.monitoring.coreos.com

NAME                 KIND
alertmanagers/main   Alertmanager.v1alpha1.monitoring.coreos.com

---- Cluster permissions ----

NAME                               AGE
clusterroles/prometheus            1d
clusterroles/prometheus-operator   1d

NAME                                      AGE
clusterrolebindings/prometheus            1d
clusterrolebindings/prometheus-operator   1d

---- Third party resources ----

NAME                                    DESCRIPTION                           VERSION(S)
prometheus.monitoring.coreos.com        Managed Prometheus server             v1alpha1
service-monitor.monitoring.coreos.com   Prometheus monitoring for a service   v1alpha1
alertmanager.monitoring.coreos.com      Managed Alertmanager cluster          v1alpha1
```

## Sample use of Deploy.sh

```
Creating record in zone 'outwide.cloud'
Created record: 'prometheus.example. 3600 IN CNAME ingress.examaple.com.'
Creating record in zone 'outwide.cloud'
Created record: 'alertmanager.example.com. 3600 IN CNAME ingress.example.com.'
service "node-exporter" created
daemonset "node-exporter" created
service "kube-state-metrics" created
deployment "kube-state-metrics" created
clusterrolebinding "kube-state-metrics" created
clusterrole "kube-state-metrics" created
serviceaccount "kube-state-metrics" created
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
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "main" not found
alertmanager "main" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "kube-state-metrics" not found
servicemonitor "kube-state-metrics" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "node-exporter" not found
servicemonitor "node-exporter" created
Error from server (NotFound): error when replacing "STDIN": thirdpartyresourcedatas.extensions "main" not found
prometheus "main" created
Done.
```

## Sample use of Delete.sh

```
Deleting record in zone 'example.com'
1 record sets deleted
Deleting record in zone 'example.com'
1 record sets deleted
ingress "alertmanager" deleted
service "alertmanager-main" deleted
ingress "prometheus" deleted
service "prometheus-main" deleted
prometheus "main" deleted
servicemonitor "kube-state-metrics" deleted
servicemonitor "node-exporter" deleted
alertmanager "main" deleted
Giving Prometheus Operator 20s to clean up...
clusterrolebinding "prometheus-operator" deleted
clusterrole "prometheus-operator" deleted
serviceaccount "prometheus-operator" deleted
deployment "prometheus-operator" deleted
configmap "alertmanager-main" deleted
clusterrolebinding "prometheus" deleted
clusterrole "prometheus" deleted
serviceaccount "prometheus" deleted
service "node-exporter" deleted
daemonset "node-exporter" deleted
service "kube-state-metrics" deleted
deployment "kube-state-metrics" deleted
clusterrolebinding "kube-state-metrics" deleted
clusterrole "kube-state-metrics" deleted
serviceaccount "kube-state-metrics" deleted
Not deleting namespace
service "prometheus-operated" deleted
service "alertmanager-operated" deleted
thirdpartyresource "prometheus.monitoring.coreos.com" deleted
thirdpartyresource "service-monitor.monitoring.coreos.com" deleted
thirdpartyresource "alertmanager.monitoring.coreos.com" deleted
Done.
```
