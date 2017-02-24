#!/bin/bash

echo "---- Prometheus namespace ----"
echo ""
kubectl get ing,svc,deployment,daemonset,statefulset,pod,sa,cm,secrets,pvc --namespace=prometheus

echo""
echo "---- Prometheus Operator configuration ----"
echo ""
kubectl get prometheus,servicemonitor,alertmanager --namespace=prometheus

echo ""
echo "---- Cluster permissions ----"
echo ""
kubectl get clusterrole,clusterrolebinding --selector=app=prometheus

echo ""
echo "---- Third party resources ----"
echo ""
kubectl get thirdpartyresource prometheus.monitoring.coreos.com service-monitor.monitoring.coreos.com alertmanager.monitoring.coreos.com
