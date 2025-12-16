#!/bin/bash

# Cleanup Script
# 清理所有 demo 創建的資源

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header "K8S Demo 資源清理"

print_warning "此腳本將刪除所有 demo 創建的資源"
echo -e "${YELLOW}確定要繼續嗎？(y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_info "已取消清理"
    exit 0
fi

# 1. 清理 ConfigMap 和 Secret
print_header "步驟 1: 清理 ConfigMap 和 Secret"
print_info "刪除 ConfigMaps..."
kubectl delete -f demo/05-config/configmap.yaml --ignore-not-found=true
print_info "刪除 Secrets..."
kubectl delete -f demo/05-config/secret.yaml --ignore-not-found=true

# 2. 清理儲存資源
print_header "步驟 2: 清理儲存資源"
print_info "刪除使用 PVC 的資源..."
kubectl delete -f demo/04-storage/pv-pvc.yaml --ignore-not-found=true
print_info "等待 Pods 終止..."
sleep 5
print_info "刪除 PVCs..."
kubectl delete pvc --all --timeout=30s 2>/dev/null || true
print_info "刪除 PVs..."
kubectl delete pv --all --timeout=30s 2>/dev/null || true
print_info "刪除 StorageClasses..."
kubectl delete -f demo/04-storage/storageclass.yaml --ignore-not-found=true

# 3. 清理進階資源
print_header "步驟 3: 清理進階資源"
print_info "刪除 CronJobs..."
kubectl delete -f demo/03-advanced/cronjob.yaml --ignore-not-found=true
print_info "刪除 Jobs..."
kubectl delete -f demo/03-advanced/job.yaml --ignore-not-found=true
print_info "刪除 StatefulSets..."
kubectl delete -f demo/03-advanced/statefulset.yaml --ignore-not-found=true
print_info "刪除 DaemonSets..."
kubectl delete -f demo/03-advanced/daemonset.yaml --ignore-not-found=true
print_info "等待資源終止..."
sleep 10

# 4. 清理健康檢查資源
print_header "步驟 4: 清理健康檢查資源"
print_info "刪除健康檢查相關資源..."
kubectl delete -f demo/02-health-checks/ --ignore-not-found=true

# 5. 清理基礎資源
print_header "步驟 5: 清理基礎資源"
print_info "刪除 Services..."
kubectl delete -f demo/01-basic/service.yaml --ignore-not-found=true
print_info "刪除 Deployments..."
kubectl delete -f demo/01-basic/deployment.yaml --ignore-not-found=true
print_info "刪除 Pods..."
kubectl delete -f demo/01-basic/pod.yaml --ignore-not-found=true

# 6. 清理測試 Pods
print_header "步驟 6: 清理測試和臨時資源"
print_info "刪除測試 Pods..."
kubectl delete pod test-pod --ignore-not-found=true
kubectl delete pod dns-test --ignore-not-found=true
kubectl delete pod tmp-shell --ignore-not-found=true
kubectl delete pvc dynamic-test-pvc --ignore-not-found=true 2>/dev/null || true

# 7. 清理 Jobs（由 CronJob 創建的）
print_header "步驟 7: 清理 CronJob 產生的 Jobs"
print_info "刪除所有 demo 相關的 Jobs..."
kubectl delete jobs -l app=cronjob-demo --ignore-not-found=true 2>/dev/null || true
kubectl delete jobs -l app=job-demo --ignore-not-found=true 2>/dev/null || true

# 8. 等待資源終止
print_header "步驟 8: 等待資源終止"
print_info "等待所有 Pods 終止..."
kubectl wait --for=delete pod --all --timeout=60s 2>/dev/null || print_warning "部分 Pods 可能還在終止中"

# 9. 清理 Namespaces（可選）
print_header "步驟 9: 清理 Namespaces"
echo -e "${YELLOW}是否要刪除 demo namespaces? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    print_info "刪除 Namespaces..."
    kubectl delete -f demo/01-basic/namespace.yaml --ignore-not-found=true
    print_info "等待 Namespaces 終止..."
    sleep 5
else
    print_info "保留 Namespaces"
fi

# 10. 清理本地檔案（可選）
print_header "步驟 10: 清理本地儲存目錄"
echo -e "${YELLOW}是否要刪除本地儲存目錄 /mnt/data? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    print_info "刪除本地儲存目錄..."
    sudo rm -rf /mnt/data 2>/dev/null || print_warning "無法刪除目錄，可能需要 sudo 權限"
else
    print_info "保留本地儲存目錄"
fi

# 11. 檢查剩餘資源
print_header "步驟 11: 檢查剩餘資源"
print_info "剩餘的 Deployments："
kubectl get deployments 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 StatefulSets："
kubectl get statefulsets 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 DaemonSets："
kubectl get daemonsets 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 Jobs："
kubectl get jobs 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 CronJobs："
kubectl get cronjobs 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 Pods："
kubectl get pods --field-selector=status.phase!=Succeeded 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 PVCs："
kubectl get pvc 2>/dev/null || echo "  無"
echo ""
print_info "剩餘的 PVs："
kubectl get pv 2>/dev/null || echo "  無"

# 完成
print_header "清理完成！"
print_info "所有 demo 資源已清理"
echo ""
print_info "如需重新執行示範："
echo "  bash scripts/demo-01-basic.sh"
echo "  bash scripts/demo-02-health.sh"
echo "  bash scripts/demo-03-advanced.sh"
echo "  bash scripts/demo-04-storage.sh"
echo ""
