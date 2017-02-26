#!/bin/bash

DEPLOY_NAMESPACE=${DEPLOY_NAMESPACE:=prometheus}

kc-ns() {
  kubectl --namespace "$DEPLOY_NAMESPACE" "$@"
}

echo "---- Deploy namespace '$DEPLOY_NAMESPACE' ----"
echo ""
kc-ns get ing,svc,endpoints,deployment,daemonset,statefulset,pod,sa,cm,secrets,pvc

echo""
echo "---- Prometheus Operator configuration ----"
echo ""
kc-ns get prometheus,servicemonitor,alertmanagers

echo""
echo "---- Extra Services to discover metrics endpoints ----"
echo ""
kubectl get --all-namespaces service -l metrics

echo ""
echo "---- Cluster permissions ----"
echo ""
kc-ns get clusterrole,clusterrolebinding --selector=app=prometheus

echo ""
echo "---- Third party resources ----"
echo ""
kubectl get thirdpartyresource prometheus.monitoring.coreos.com service-monitor.monitoring.coreos.com alertmanager.monitoring.coreos.com
