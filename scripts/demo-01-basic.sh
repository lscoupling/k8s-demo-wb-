#!/bin/bash

# Demo 01: 基礎資源示範
# 展示 Pod、Deployment、Service、Namespace 的基本用法

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 輔助函數
print_header() {
    echo -e "\n${BLUE}=================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================${NC}\n"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_user() {
    echo -e "\n${YELLOW}按 Enter 繼續...${NC}"
    read
}

# 檢查 kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl 未安裝，請先安裝 kubectl"
    exit 1
fi

print_header "K8S Demo 01: 基礎資源示範"

# 1. 創建 Namespace
print_header "步驟 1: 創建 Namespace"
print_info "Namespace 用於邏輯隔離資源"
kubectl apply -f demo/01-basic/namespace.yaml
print_info "查看 Namespace："
kubectl get namespaces k8s-demo k8s-demo-limited
wait_for_user

# 2. 創建簡單的 Pod
print_header "步驟 2: 創建基本 Pod"
print_info "Pod 是 K8S 最小的部署單元"
kubectl apply -f demo/01-basic/pod.yaml
print_info "等待 Pod 啟動..."
kubectl wait --for=condition=Ready pod/nginx-pod --timeout=60s
print_info "查看 Pod 狀態："
kubectl get pods nginx-pod -o wide
print_info "查看 Pod 詳細資訊："
kubectl describe pod nginx-pod | head -30
wait_for_user

# 3. 查看多容器 Pod
print_header "步驟 3: 多容器 Pod 示範"
print_info "一個 Pod 可以包含多個容器"
kubectl wait --for=condition=Ready pod/multi-container-pod --timeout=60s 2>/dev/null || true
print_info "查看多容器 Pod："
kubectl get pod multi-container-pod
print_info "查看容器列表："
kubectl get pod multi-container-pod -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n'
print_info "\n測試內容生成器（查看 Sidecar 容器生成的內容）："
kubectl exec multi-container-pod -c app -- cat /usr/share/nginx/html/index.html
wait_for_user

# 4. 創建 Deployment
print_header "步驟 4: 創建 Deployment"
print_info "Deployment 管理 Pod 的生命週期"
kubectl apply -f demo/01-basic/deployment.yaml
print_info "等待 Deployment 就緒..."
kubectl wait --for=condition=Available deployment/nginx-deployment --timeout=90s
print_info "查看 Deployment："
kubectl get deployment nginx-deployment
print_info "查看 Deployment 管理的 Pods："
kubectl get pods -l app=nginx
wait_for_user

# 5. 擴展 Deployment
print_header "步驟 5: 擴展 Deployment"
print_info "將副本數從 3 擴展到 5"
kubectl scale deployment nginx-deployment --replicas=5
print_info "觀察 Pod 擴展過程："
kubectl get pods -l app=nginx -w &
WATCH_PID=$!
sleep 10
kill $WATCH_PID 2>/dev/null || true
print_info "\n當前 Pod 數量："
kubectl get pods -l app=nginx --no-headers | wc -l
wait_for_user

# 6. 創建 Service
print_header "步驟 6: 創建 Service"
print_info "Service 為 Pod 提供穩定的網路訪問"
kubectl apply -f demo/01-basic/service.yaml
print_info "查看所有 Service："
kubectl get svc
print_info "\n查看 Service 詳細資訊："
kubectl describe svc nginx-service | head -20
print_info "\n查看 Service Endpoints："
kubectl get endpoints nginx-service
wait_for_user

# 7. 測試 Service 連接
print_header "步驟 7: 測試 Service 連接"
print_info "創建測試 Pod 來訪問 Service"
kubectl run test-pod --image=busybox --rm -it --restart=Never -- /bin/sh -c "
    echo '測試 ClusterIP Service:'
    wget -O- -q nginx-service
    echo ''
    echo '測試完成！'
" || print_warning "測試 Pod 執行完畢"
wait_for_user

# 8. 滾動更新
print_header "步驟 8: 滾動更新示範"
print_info "更新 nginx 映像版本"
print_info "當前映像版本："
kubectl get deployment nginx-deployment -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
print_info "\n更新到 nginx:1.22..."
kubectl set image deployment/nginx-deployment nginx=nginx:1.22
print_info "觀察滾動更新過程："
kubectl rollout status deployment/nginx-deployment
print_info "\n更新完成！新的映像版本："
kubectl get deployment nginx-deployment -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
wait_for_user

# 9. 查看更新歷史
print_header "步驟 9: 查看部署歷史"
kubectl rollout history deployment/nginx-deployment
print_info "\n查看特定版本的詳細資訊："
kubectl rollout history deployment/nginx-deployment --revision=2
wait_for_user

# 10. 回滾
print_header "步驟 10: 回滾到上一個版本"
print_info "執行回滾..."
kubectl rollout undo deployment/nginx-deployment
print_info "等待回滾完成..."
kubectl rollout status deployment/nginx-deployment
print_info "\n回滾後的映像版本："
kubectl get deployment nginx-deployment -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
wait_for_user

# 11. 查看資源使用
print_header "步驟 11: 查看資源摘要"
print_info "所有 Deployments："
kubectl get deployments
echo ""
print_info "所有 Pods："
kubectl get pods -o wide
echo ""
print_info "所有 Services："
kubectl get services
echo ""
print_info "所有 Endpoints："
kubectl get endpoints
wait_for_user

# 完成
print_header "Demo 01 完成！"
print_info "您已經學習了："
echo "  ✓ 創建和管理 Namespace"
echo "  ✓ 創建基本 Pod 和多容器 Pod"
echo "  ✓ 使用 Deployment 管理應用"
echo "  ✓ 擴展 Deployment 副本"
echo "  ✓ 創建 Service 實現服務發現"
echo "  ✓ 執行滾動更新和回滾"
echo ""
print_info "清理資源："
echo "  bash scripts/cleanup.sh"
echo ""
print_info "下一個示範："
echo "  bash scripts/demo-02-health.sh"
echo ""
