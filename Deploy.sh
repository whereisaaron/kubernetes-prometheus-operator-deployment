#!/bin/bash

#
# Deploy prometheus operator, prometheus, and exporters
#
# Before using this you need to:
# - Copy the '-example' files in 'prometheus-alerts' to create your local alerts config
# - Create a basic auth secret or comment the auth out of 'prometheus-ingress/*.yaml'
# - Check the persistent storage settings in 'prometheus-operator-config/*.yaml' files
# - Define DEPLOY_AWS_ROUTE53_PROFILE and DEPLOY_INGRESS_DOMAIN if you have cli53 or comment out
# - Define the other DEPLOY_ environment variables below
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

# Check user has configured alerts
if [[ -z "$(ls prometheus-alerts/*.yaml)" ]]; then
  echo "Copy the '-example' files in 'prometheus-alerts' to create your local alerts config"
  exit
fi

# Create DNS records for Prometheus and Alertmanager
if [[ -n "${DEPLOY_AWS_ROUTE53_PROFILE}" ]]; then
  : ${DEPLOY_INGRESS_DOMAIN?"Must define DEPLOY_INGRESS_DOMAIN"}
  ./create-cname-dns-record.sh --domain=${DEPLOY_PROMETHEUS_DOMAIN} --cname=${DEPLOY_INGRESS_DOMAIN} --profile=${DEPLOY_AWS_ROUTE53_PROFILE}
  ./create-cname-dns-record.sh --domain=${DEPLOY_ALERTMANAGER_DOMAIN} --cname=${DEPLOY_INGRESS_DOMAIN} --profile=${DEPLOY_AWS_ROUTE53_PROFILE}
else
  echo "No AWS Route53 profiles configured, not creating domain names"
fi

# Create namespace if necessary
echo "Deploying to namespace '$DEPLOY_NAMESPACE'"
if [[ -z $(kubectl get namespace "$DEPLOY_NAMESPACE" -o name 2> /dev/null) ]]; then
  kubectl create namespace "$DEPLOY_NAMESPACE"
  kubectl label namespace app=promethus env=live
fi

# Prometheus Exporters
kc-ns apply -f node-exporter
kc-ns apply -f kube-state-metrics
kubectl apply -f kube-system-metrics

# Prometheus Operator and Service Account for Prometheus instances
for file in prometheus-service-account/*.yaml prometheus-operator/*.yaml; do
  envsubst < $file | kc-ns apply -f -
done

# Update the prometheus-main-rules from the rules file collection
kc-ns create configmap --dry-run=true prometheus-main-rules \
  --from-file=prometheus-alerts/rules/ -o yaml > prometheus-alerts/prometheus-rules-configmap.yaml

# Prometheus/Alertmanager configuration and ingress
for file in prometheus-alerts/*.yaml prometheus-ingress/*.yaml; do
  envsubst < $file | kc-ns apply -f -
done

# Wait for third party resources created by prometheus-operator to be ready
printf "Waiting for Operator to register third party objects..."
until kc-ns get servicemonitor > /dev/null 2>&1; do sleep 1; printf "."; done
until kc-ns get prometheus > /dev/null 2>&1; do sleep 1; printf "."; done
until kc-ns get alertmanager > /dev/null 2>&1; do sleep 1; printf "."; done
echo "done."

# Prometheus Operator and monitor configuraton, third party resources cannot be apply'd
for file in prometheus-operator-config/*.yaml; do
  envsubst < $file | kc-ns replace -f -
  if [[ $? -ne 0 ]]; then
    envsubst < $file | kc-ns create -f -
  fi
done

# End
echo "Done."
