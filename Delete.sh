#!/bin/bash

#
# Delete prometheus operator, prometheus, and exporters
# Does not delete namespace or thirdpartyresources
#

# Prometheus Operator configuration for Prometheus with ServiceMonitors
kubectl delete --ignore-not-found -f prometheus-operator-config
echo "Giving Prometheus Operator 20s to clean up..."
sleep 20

# Prometheus Operator and Service Account for Prometheus instances
kubectl delete --ignore-not-found -f prometheus-operator
kubectl delete --ignore-not-found -f prometheus-service-account

# Prometheus Exporters
kubectl delete --ignore-not-found -f node-exporter
kubectl delete --ignore-not-found -f kube-state-metrics

# Delete namespace - disabled, do not delete namespace
#kubectl delete --ignore-not-found -f prometheus-namespace.yaml
echo "Not deleting namespace"

# Delete services
kubectl delete --ignore-not-found --namespace=prometheus service prometheus-operated alertmanager-operated

# Delete the third party resources
kubectl delete --ignore-not-found thirdpartyresource \
  prometheus.monitoring.coreos.com \
  service-monitor.monitoring.coreos.com \
  alertmanager.monitoring.coreos.com 

# End
echo "Done."
