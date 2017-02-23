#!/bin/bash

#
# Deploy prometheus operator, prometheus, and exporters
#

# Create namespace if necessary
if [[ -z $(kubectl get namespace prometheus -o name 2> /dev/null) ]]; then
  kubectl create -f prometheus-namespace.yaml
fi

# Prometheus Exporters
kubectl apply -f node-exporter
kubectl apply -f kube-state-metrics

# Prometheus Operator and Service Account for Prometheus instances
kubectl apply -f prometheus-operator
kubectl apply -f prometheus-service-account

# Prometheus Operator configuration for Prometheus with ServiceMonitors
kubectl create -f prometheus-operator-config

# End
echo "Done."
