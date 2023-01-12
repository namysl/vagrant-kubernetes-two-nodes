#!/bin/bash

install_k6(){
  echo "Installing K6"
  sudo gpg -k
  sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
  echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
  sudo apt-get update
  sudo apt-get install k6
  echo "K6 VERSION: $(k6 version)"
}

run_nginx(){
  microk8s kubectl apply -f vagrant-kubernetes-two-nodes/deployment.yaml
  microk8s kubectl autoscale deployment nginx-kube --min=3 --max=10 --cpu-percent=60
  microk8s kubectl apply -f vagrant-kubernetes-two-nodes/service.yaml
}

run_dashboard(){
  microk8s enable dns dashboard storage
  microk8s kubectl patch svc kubernetes-dashboard -n kube-system --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30000}]'
}

run_prometheus(){
  microk8s helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  microk8s helm install prometheus prometheus-community/prometheus
  microk8s kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-np
  microk8s kubectl patch svc prometheus-server-np --type='json' --patch='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30002}]'
}

run_grafana(){
  microk8s helm repo add grafana https://grafana.github.io/helm-charts
  microk8s helm install grafana grafana/grafana
  microk8s kubectl expose service grafana --type=NodePort --target-port=3000 --name=grafana-np
  microk8s kubectl patch svc grafana-np --type='json' --patch='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30003}]'
}

#vi /var/snap/microk8s/current/args/kubelet
#--container-runtime=docker
#microk8s stop
#microk8s start

microk8s kubectl taint nodes master node-role.kubernetes.io/master=:NoSchedule
microk8s kubectl label node master node-role.kubernetes.io/master=

install_k6
run_nginx
run_dashboard
#run_prometheus
#run_grafana

echo "NEXT STEPS - PERFORM MANUALLY:

- ENABLE & GET ACCESS TO KUBERNETES DASHBOARD:
microk8s dashboard-proxy &
microk8s kubectl proxy --address='0.0.0.0' --disable-filter=true &

- PORT FORWARD THE SERVICES:
microk8s kubectl port-forward service/nginx-kube --address 0.0.0.0 30001:80 &
microk8s kubectl port-forward service/prometheus-server-np --address 0.0.0.0 30002:80 &
microk8s kubectl port-forward service/grafana-np --address 0.0.0.0 30003:80 &

- GET ACCESS TO GRAFANA:
microk8s kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

- ADD DATA SOURCES IN GRAFANA:
URL: http://prometheus-server:80

- IMPORT DASHBOARD IN GRAFANA:
e.g. ID: 1860

- GET URL OF THE SERVICE:
microk8s kubectl get service nginx-kube -o go-template={{.spec.clusterIP}}"
