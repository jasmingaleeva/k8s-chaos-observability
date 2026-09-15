.PHONY: help all cluster-up deploy-app deploy-monitoring deploy-chaos chaos-pod-kill chaos-network-delay chaos-stress-cpu chaos-clean load-test status clean

help:
	@echo "Available commands:"
	@echo "  make all                  - Deploy entire lab (cluster + app + monitoring + chaos)"
	@echo "  make cluster-up           - Create KinD Kubernetes cluster"
	@echo "  make deploy-app           - Deploy Google Boutique microservices"
	@echo "  make deploy-monitoring    - Deploy Prometheus, Loki, Grafana & SRE Dashboards"
	@echo "  make deploy-chaos         - Deploy Chaos Mesh platform"
	@echo "  make load-test            - Launch Locust load test inside Kubernetes"
	@echo "  make chaos-pod-kill       - Inject PodKill fault on cartservice"
	@echo "  make chaos-network-delay  - Inject 500ms network delay on productcatalogservice"
	@echo "  make chaos-stress-cpu     - Inject CPU stress chaos on frontend"
	@echo "  make chaos-clean          - Remove all active chaos experiments"
	@echo "  make status               - Show cluster endpoints and pod status"
	@echo "  make clean                - Destroy cluster and reset environment"

all: cluster-up deploy-app deploy-monitoring deploy-chaos
	@echo "=== Lab successfully deployed! Run 'make status' for endpoints ==="

cluster-up:
	@echo "--> Creating KinD cluster 'chaos-lab'..."
	kind create cluster --config cluster/kind-config.yaml

deploy-app:
	@echo "--> Deploying Google Online Boutique microservices..."
	kubectl apply -f apps/boutique/namespace.yaml
	kubectl apply -n boutique -f apps/boutique/release.yaml
	kubectl scale -n boutique deployment/loadgenerator --replicas=0
	kubectl wait --namespace boutique --for=condition=ready pod -l app=frontend --timeout=120s

deploy-monitoring:
	@echo "--> Deploying Observability Stack (Prometheus, Loki, Grafana)..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
	helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
	helm repo update
	kubectl create namespace monitoring 2>/dev/null || true
	helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring -f monitoring/values/prometheus-values.yaml
	helm upgrade --install loki grafana/loki-stack --namespace monitoring -f monitoring/values/loki-values.yaml
	kubectl apply -f monitoring/dashboards/grafana-datasources-cm.yaml
	kubectl apply -f monitoring/dashboards/sre-golden-signals-cm.yaml
	kubectl apply -f monitoring/alerts/golden-signals-rules.yaml
	kubectl rollout restart deployment kube-prometheus-stack-grafana -n monitoring

deploy-chaos:
	@echo "--> Deploying Chaos Mesh..."
	helm repo add chaos-mesh https://charts.chaos-mesh.org 2>/dev/null || true
	helm repo update
	helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --create-namespace -f chaos/values.yaml
	kubectl wait --namespace chaos-mesh --for=condition=ready pod --all --timeout=120s

load-test:
	@echo "--> Starting Locust load generation Job..."
	kubectl delete job locust-load-test -n boutique --ignore-not-found
	kubectl apply -f load-testing/k8s-locust-job.yaml
	@echo "Follow logs with: kubectl logs -n boutique -l job-name=locust-load-test -f"

chaos-pod-kill:
	@echo "--> Triggering PodKill Chaos on cartservice..."
	kubectl apply -f chaos/pod-kill.yaml

chaos-network-delay:
	@echo "--> Triggering 500ms NetworkDelay Chaos on productcatalogservice..."
	kubectl apply -f chaos/network-delay.yaml

chaos-stress-cpu:
	@echo "--> Triggering CPU Stress Chaos on frontend..."
	kubectl apply -f chaos/stress-cpu.yaml

chaos-clean:
	@echo "--> Cleaning up chaos experiments..."
	kubectl delete -f chaos/pod-kill.yaml --ignore-not-found
	kubectl delete -f chaos/network-delay.yaml --ignore-not-found
	kubectl delete -f chaos/stress-cpu.yaml --ignore-not-found

status:
	@echo "=================================================="
	@echo "            k8s-chaos-observability URLs          "
	@echo "=================================================="
	@echo "  Online Boutique App    : http://localhost:8080"
	@echo "  Grafana SRE Dashboard  : http://localhost:3000 (admin / admin)"
	@echo "  Chaos Mesh Dashboard   : http://localhost:2333"
	@echo "=================================================="
	@kubectl get pods -A

clean:
	@echo "--> Deleting KinD cluster 'chaos-lab'..."
	kind delete cluster --name chaos-lab
