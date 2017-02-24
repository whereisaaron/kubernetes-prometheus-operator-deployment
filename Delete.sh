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
: ${DEPLOY_INGRESS_DOMAIN?"Must define DEPLOY_AWS_ROUTE53_PROFILE"}
: ${DEPLOY_ACME_CLASS?"Must define DEPLOY_ACME_CLASS for kube-cert-manager"}
DEPLOY_KCM_LABEL=${DEPLOY_KCM_LABEL:=stable.k8s.psg.io/kcm.class}

# Delete DNS records for Prometheus and Alertmanager
if [[ -n "${DEPLOY_AWS_ROUTE53_PROFILE}" ]]; then
  ./create-cname-dns-record.sh --domain=${DEPLOY_PROMETHEUS_DOMAIN} --delete --profile=${DEPLOY_AWS_ROUTE53_PROFILE}
  ./create-cname-dns-record.sh --domain=${DEPLOY_ALERTMANAGER_DOMAIN} --delete --profile=${DEPLOY_AWS_ROUTE53_PROFILE}
else
  echo "No AWS Route53 profiles configured, not deleting domain names"
fi

# Delete Prometheus Operator configuration for Prometheus and ServiceMonitors
for file in prometheus-operator-config/*.yaml; do
  envsubst < $file | kubectl delete --ignore-not-found -f -
done
echo "Giving Prometheus Operator 20s to clean up..."
sleep 20

# Delete Prometheus Operator, Ingress and Service Account for Prometheus
for file in prometheus-alerts/*.yaml prometheus-ingress/*.yaml; do
  envsubst < $file | kubectl delete --ignore-not-found -f -
done
kubectl delete --ignore-not-found -f prometheus-service-account

# Delete Prometheus Exporters
kubectl delete --ignore-not-found -f node-exporter
kubectl delete --ignore-not-found -f kube-state-metrics

# Delete namespace - disabled, do not delete namespace
#kubectl delete --ignore-not-found -f prometheus-namespace.yaml
echo "Not deleting namespace"

# Delete services created by prometheus-operator
kubectl delete --ignore-not-found --namespace=prometheus service prometheus-operated alertmanager-operated

# Delete the third party resources created by prometheus-operator
kubectl delete --ignore-not-found thirdpartyresource \
  prometheus.monitoring.coreos.com \
  service-monitor.monitoring.coreos.com \
  alertmanager.monitoring.coreos.com 

# End
echo "Done."
