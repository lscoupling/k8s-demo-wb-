#!/bin/bash

# Demo 02: 健康檢查示範
# 展示 Liveness、Readiness、Startup Probe 的用法

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

wait_for_user() {
    echo -e "\n${YELLOW}按 Enter 繼續...${NC}"
    read
}

print_header "K8S Demo 02: 健康檢查示範"

# 1. Liveness Probe
print_header "步驟 1: Liveness Probe（存活探針）"
print_info "Liveness Probe 檢測容器是否存活"
print_info "如果失敗，kubelet 會重啟容器"
echo ""
print_info "部署帶 HTTP Liveness Probe 的 Pod..."
kubectl apply -f demo/02-health-checks/liveness.yaml
print_info "等待 Pods 啟動..."
sleep 10
print_info "\n查看 Pods 狀態："
kubectl get pods -l app=liveness-demo
wait_for_user

# 2. 查看 Liveness 配置
print_header "步驟 2: 查看 Liveness 配置"
print_info "查看 HTTP Liveness Probe 配置："
kubectl describe pod liveness-http | grep -A 10 "Liveness:"
wait_for_user

# 3. 模擬容器崩潰
print_header "步驟 3: 模擬應用程式崩潰"
print_info "liveness-demo-crash 會在 60 秒後刪除 index.html"
print_info "這會導致 Liveness Probe 失敗，觸發容器重啟"
print_info "\n當前 Pod 狀態："
kubectl get pod liveness-demo-crash
print_info "\n觀察 Pod 重啟過程（約 60 秒後會重啟）..."
print_warning "這可能需要等待約 60-90 秒"
echo ""
kubectl get pod liveness-demo-crash -w &
WATCH_PID=$!
sleep 90
kill $WATCH_PID 2>/dev/null || true
print_info "\n查看重啟次數："
kubectl get pod liveness-demo-crash -o jsonpath='{.status.containerStatuses[0].restartCount}'
echo ""
print_info "\n查看事件："
kubectl describe pod liveness-demo-crash | grep -A 5 "Events:"
wait_for_user

# 4. Readiness Probe
print_header "步驟 4: Readiness Probe（就緒探針）"
print_info "Readiness Probe 檢測容器是否準備好接收流量"
print_info "如果失敗，Pod 不會被加入 Service Endpoints"
echo ""
kubectl apply -f demo/02-health-checks/readiness.yaml
print_info "等待 Deployment 就緒..."
kubectl wait --for=condition=Available deployment/readiness-http-deployment --timeout=60s
print_info "\n查看 Pods："
kubectl get pods -l app=readiness-demo
print_info "\n查看 Service Endpoints："
kubectl get endpoints readiness-service
wait_for_user

# 5. Readiness vs Liveness
print_header "步驟 5: Readiness vs Liveness 的區別"
print_info "查看同時使用兩種 Probe 的 Pod："
kubectl get pod readiness-liveness-combo -o wide 2>/dev/null || print_warning "Pod 還在啟動中..."
print_info "\n查看 Pod 的 Ready 狀態："
kubectl get pod readiness-liveness-combo -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | python3 -m json.tool 2>/dev/null || echo "Pod 還未就緒"
wait_for_user

# 6. 暖機示範
print_header "步驟 6: 應用程式暖機示範"
print_info "readiness-warmup-demo 模擬應用程式初始化過程"
print_info "觀察 Pod 從 Not Ready 到 Ready 的過程"
echo ""
kubectl wait --for=condition=Ready pod -l app=warmup-demo --timeout=60s 2>/dev/null || print_warning "等待暖機完成..."
print_info "\n查看 Pods 就緒狀態："
kubectl get pods -l app=warmup-demo
print_info "\n查看 Service Endpoints（只有 Ready 的 Pod 才會被加入）："
kubectl get endpoints warmup-service
wait_for_user

# 7. Startup Probe
print_header "步驟 7: Startup Probe（啟動探針）"
print_info "Startup Probe 用於慢啟動的應用程式"
print_info "在 Startup 成功之前，Liveness 和 Readiness 會被禁用"
echo ""
kubectl apply -f demo/02-health-checks/startup.yaml
print_info "等待 Pods 啟動..."
sleep 15
print_info "\n查看慢啟動應用的狀態："
kubectl get pods -l app=startup-demo
wait_for_user

# 8. Startup Probe 詳細資訊
print_header "步驟 8: 查看 Startup Probe 配置"
print_info "查看完整配置的 Pod："
kubectl describe pod -l app=startup-complete | grep -A 15 "Startup:"
print_info "\n查看 Liveness Probe（在 Startup 成功後才啟動）："
kubectl describe pod -l app=startup-complete | grep -A 8 "Liveness:"
wait_for_user

# 9. 模擬資料庫啟動
print_header "步驟 9: 資料庫啟動模擬"
print_info "startup-database-simulation 模擬資料庫的啟動過程"
print_info "查看 Pod 日誌，觀察啟動階段："
sleep 5
kubectl logs startup-database-simulation --tail=50 2>/dev/null || print_warning "Pod 還在啟動中..."
wait_for_user

# 10. 測試自我修復
print_header "步驟 10: 測試自我修復能力"
print_info "刪除一個 Pod，觀察 Deployment 自動重建"
print_info "\n當前 Pods："
kubectl get pods -l app=readiness-demo
FIRST_POD=$(kubectl get pods -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}')
print_info "\n刪除 Pod: $FIRST_POD"
kubectl delete pod $FIRST_POD
print_info "觀察新 Pod 創建過程..."
sleep 5
kubectl get pods -l app=readiness-demo -w &
WATCH_PID=$!
sleep 15
kill $WATCH_PID 2>/dev/null || true
print_info "\n\n新的 Pods："
kubectl get pods -l app=readiness-demo
wait_for_user

# 11. 健康檢查最佳實踐
print_header "步驟 11: 健康檢查最佳實踐"
echo "健康檢查使用建議："
echo ""
echo "1. Liveness Probe（存活探針）："
echo "   ✓ 檢測應用是否存活"
echo "   ✓ 失敗會重啟容器"
echo "   ✓ 適用於：應用死鎖、無回應"
echo ""
echo "2. Readiness Probe（就緒探針）："
echo "   ✓ 檢測應用是否準備好接收流量"
echo "   ✓ 失敗會從 Service 中移除"
echo "   ✓ 適用於：暖機、依賴服務未就緒"
echo ""
echo "3. Startup Probe（啟動探針）："
echo "   ✓ 給慢啟動應用更多時間"
echo "   ✓ 成功前禁用其他探針"
echo "   ✓ 適用於：需要長時間初始化的應用"
echo ""
echo "配置建議："
echo "   • initialDelaySeconds: 根據應用啟動時間設定"
echo "   • periodSeconds: 檢查間隔（通常 5-10 秒）"
echo "   • timeoutSeconds: 超時時間（通常 1-3 秒）"
echo "   • failureThreshold: 連續失敗次數（通常 3 次）"
wait_for_user

# 完成
print_header "Demo 02 完成！"
print_info "您已經學習了："
echo "  ✓ Liveness Probe 的用法和自動重啟"
echo "  ✓ Readiness Probe 的用法和服務發現"
echo "  ✓ Startup Probe 處理慢啟動應用"
echo "  ✓ 三種 Probe 的配合使用"
echo "  ✓ Kubernetes 的自我修復能力"
echo ""
print_info "清理資源："
echo "  bash scripts/cleanup.sh"
echo ""
print_info "下一個示範："
echo "  bash scripts/demo-03-advanced.sh"
echo ""
