#!/bin/bash

#
# Delete prometheus operator, prometheus, and exporters
# Does not delete namespace, thirdpartyresources, or persistent volumes
# Deletes CNAMESs only if DEPLOY_AWS_ROUTE53_PROFILE defined, or else comment out below
#

: ${DEPLOY_PROMETHEUS_DOMAIN?"Must define DEPLOY_PROMETHEUS_DOMAIN"}
: ${DEPLOY_ALERTMANAGER_DOMAIN?"Must define DEPLOY_ALERTMANAGER_DOMAIN"}
: ${DEPLOY_BASIC_AUTH_SECRET_NAME?"Must define DEPLOY_BASIC_AUTH_SECRET_NAME"}
: ${DEPLOY_AWS_ROUTE53_PROFILE?"Must define DEPLOY_AWS_ROUTE53_PROFILE"}
: ${DEPLOY_INGRESS_DOMAIN?"Must define DEPLOY_INGRESS_DOMAIN"}
: ${DEPLOY_ACME_CLASS?"Must define DEPLOY_ACME_CLASS for kube-cert-manager"}
DEPLOY_KCM_LABEL=${DEPLOY_KCM_LABEL:=stable.k8s.psg.io/kcm.class}
DEPLOY_NAMESPACE=${DEPLOY_NAMESPACE:=prometheus}

kc-ns() {
  kubectl --namespace "$DEPLOY_NAMESPACE" "$@"
}

# Delete DNS records for Prometheus and Alertmanager
if [[ -n "${DEPLOY_AWS_ROUTE53_PROFILE}" ]]; then
  ./create-cname-dns-record.sh --domain=${DEPLOY_PROMETHEUS_DOMAIN} --delete --profile=${DEPLOY_AWS_ROUTE53_PROFILE}
  ./create-cname-dns-record.sh --domain=${DEPLOY_ALERTMANAGER_DOMAIN} --delete --profile=${DEPLOY_AWS_ROUTE53_PROFILE}
else
  echo "No AWS Route53 profiles configured, not deleting domain names"
fi

# Delete Prometheus Operator configuration for Prometheus and ServiceMonitors
for file in prometheus-operator-config/*.yaml; do
  envsubst < $file | kc-ns delete --ignore-not-found -f -
done
echo "Giving Prometheus Operator 10s to clean up..."
sleep 10

# Delete Prometheus Operator, Ingress and Service Account for Prometheus
for file in prometheus-alerts/*.yaml prometheus-ingress/*.yaml; do
  envsubst < $file | kc-ns delete --ignore-not-found -f -
done

# Delete Prometheus Operator and Service Account for Prometheus instances
for file in prometheus-service-account/*.yaml prometheus-operator/*.yaml; do
  envsubst < $file | kc-ns delete -f -
done

# Delete Prometheus Exporters
kc-ns delete --ignore-not-found -f node-exporter
kc-ns delete --ignore-not-found -f kube-state-metrics
kubectl delete --ignore-not-found -f kube-dns-metrics

# Delete services created by prometheus-operator
kc-ns delete --ignore-not-found service prometheus-operated alertmanager-operated

# Delete namespace - disabled, do not delete namespace
#kubectl delete --ignore-not-found namespace "$DEPLOY_NAMESPACE"
echo "Not deleting namespace"

# Delete the third party resources created by prometheus-operator
kubectl delete --ignore-not-found thirdpartyresource \
  prometheus.monitoring.coreos.com \
  service-monitor.monitoring.coreos.com \
  alertmanager.monitoring.coreos.com 

# End
echo "Done."
