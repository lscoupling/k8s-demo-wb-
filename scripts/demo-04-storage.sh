#!/bin/bash

# Demo 04: 儲存管理示範
# 展示 PV、PVC、StorageClass 的用法

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

print_header "K8S Demo 04: 儲存管理示範"

print_warning "注意：此示範需要支援持久化儲存的 K8S 環境"
print_warning "在某些本地環境（如 Kind）中，可能需要額外配置"
wait_for_user

# 1. StorageClass
print_header "步驟 1: 查看 StorageClass"
print_info "StorageClass 定義了動態供應儲存的模板"
kubectl apply -f demo/04-storage/storageclass.yaml
print_info "\n查看 StorageClasses："
kubectl get storageclass
print_info "\n查看 local-storage StorageClass 詳細資訊："
kubectl describe storageclass local-storage
wait_for_user

# 2. PersistentVolume
print_header "步驟 2: 創建 PersistentVolume (PV)"
print_info "PV 是叢集管理員預先配置的儲存資源"
print_info "\n創建目錄（模擬儲存）："
sudo mkdir -p /mnt/data/pv1 /mnt/data/pv2 2>/dev/null || print_warning "無法創建目錄，可能需要 sudo 權限"
kubectl apply -f demo/04-storage/pv-pvc.yaml
print_info "\n查看 PVs："
kubectl get pv
print_info "\n查看 PV 詳細資訊："
kubectl describe pv local-pv-1 | head -30
wait_for_user

# 3. PersistentVolumeClaim
print_header "步驟 3: 創建 PersistentVolumeClaim (PVC)"
print_info "PVC 是使用者請求儲存的方式"
print_info "\n查看 PVCs："
kubectl get pvc
print_info "\n查看 PVC 詳細資訊："
kubectl describe pvc my-pvc
print_info "\n查看 PVC 和 PV 的綁定："
kubectl get pvc my-pvc -o jsonpath='PVC: {.metadata.name}, Status: {.status.phase}, Volume: {.spec.volumeName}'
echo ""
wait_for_user

# 4. 使用 PVC 的 Pod
print_header "步驟 4: 在 Pod 中使用 PVC"
print_info "等待 Pod 啟動..."
kubectl wait --for=condition=Ready pod/pod-with-pvc --timeout=60s
print_info "\n查看 Pod："
kubectl get pod pod-with-pvc -o wide
print_info "\n查看 Pod 的掛載資訊："
kubectl describe pod pod-with-pvc | grep -A 5 "Mounts:"
wait_for_user

# 5. 測試持久化
print_header "步驟 5: 測試資料持久化"
print_info "查看 Pod 寫入的內容："
kubectl exec pod-with-pvc -- cat /usr/share/nginx/html/index.html
print_info "\n寫入新資料到 PVC："
kubectl exec pod-with-pvc -- sh -c 'echo "Updated at $(date)" >> /usr/share/nginx/html/index.html'
print_info "\n查看更新後的內容："
kubectl exec pod-with-pvc -- cat /usr/share/nginx/html/index.html
wait_for_user

# 6. 刪除 Pod 測試持久化
print_header "步驟 6: 刪除 Pod，測試資料是否保留"
print_info "刪除 Pod..."
kubectl delete pod pod-with-pvc
print_info "等待 5 秒..."
sleep 5
print_info "\n重新創建 Pod..."
kubectl apply -f demo/04-storage/pv-pvc.yaml
kubectl wait --for=condition=Ready pod/pod-with-pvc --timeout=60s
print_info "\n檢查資料是否還在："
kubectl exec pod-with-pvc -- cat /usr/share/nginx/html/index.html
print_info "\n✓ 資料保留成功！"
wait_for_user

# 7. 使用 PVC 的 Deployment
print_header "步驟 7: Deployment 使用 PVC"
print_info "部署使用 PVC 的 Deployment..."
kubectl wait --for=condition=Available deployment/webapp-with-pvc --timeout=60s 2>/dev/null || print_warning "等待 Deployment 就緒..."
sleep 5
print_info "\n查看 Deployment："
kubectl get deployment webapp-with-pvc
print_info "\n查看 Pods："
kubectl get pods -l app=webapp
print_info "\n查看所有 PVCs："
kubectl get pvc
wait_for_user

# 8. 共享儲存
print_header "步驟 8: 多容器共享 PVC"
print_info "部署共享儲存的 Pod..."
kubectl wait --for=condition=Ready pod/shared-storage-pod --timeout=60s 2>/dev/null || print_warning "等待 Pod 就緒..."
sleep 5
print_info "\n查看 writer 容器的日誌（寫入資料）："
kubectl logs shared-storage-pod -c writer --tail=5
print_info "\n查看 reader 容器的日誌（讀取資料）："
kubectl logs shared-storage-pod -c reader --tail=5
print_info "\n兩個容器共享同一個 PVC！"
wait_for_user

# 9. 儲存類別比較
print_header "步驟 9: 不同 StorageClass 的使用場景"
echo "StorageClass 使用場景："
echo ""
echo "1. local-storage（本地儲存）："
echo "   • 優點：速度快、成本低"
echo "   • 缺點：不支援多節點存取、無法遷移"
echo "   • 適用：測試、開發環境"
echo ""
echo "2. aws-ebs-gp3（AWS EBS）："
echo "   • 優點：可靠、可擴展、支援快照"
echo "   • 缺點：只支援單節點掛載（RWO）"
echo "   • 適用：資料庫、狀態應用"
echo ""
echo "3. aws-efs（AWS EFS）："
echo "   • 優點：支援多節點讀寫（RWX）"
echo "   • 缺點：成本較高、延遲較大"
echo "   • 適用：共享檔案、內容管理"
echo ""
echo "AccessModes 說明："
echo "   • ReadWriteOnce (RWO)：單節點讀寫"
echo "   • ReadOnlyMany (ROX)：多節點唯讀"
echo "   • ReadWriteMany (RWX)：多節點讀寫"
wait_for_user

# 10. 動態供應
print_header "步驟 10: StorageClass 動態供應"
print_info "當 PVC 請求儲存時，StorageClass 會自動創建 PV"
print_info "\n創建使用動態供應的 PVC..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-test-pvc
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF
print_info "\n查看 PVC 狀態："
kubectl get pvc dynamic-test-pvc
print_info "\n注意：local-storage 不支援動態供應，需要手動創建 PV"
wait_for_user

# 11. PV 回收策略
print_header "步驟 11: PV 回收策略"
echo "PersistentVolumeReclaimPolicy 說明："
echo ""
echo "1. Retain（保留）："
echo "   • PVC 刪除後，PV 保留"
echo "   • 資料需要手動清理"
echo "   • 適用：重要資料"
echo ""
echo "2. Delete（刪除）："
echo "   • PVC 刪除後，PV 和底層儲存都會被刪除"
echo "   • 適用：動態供應的儲存"
echo ""
echo "3. Recycle（回收 - 已廢棄）："
echo "   • 清空資料後重新使用"
echo ""
print_info "查看當前 PV 的回收策略："
kubectl get pv -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy
wait_for_user

# 12. 儲存資源摘要
print_header "步驟 12: 儲存資源摘要"
print_info "StorageClasses："
kubectl get storageclass
echo ""
print_info "PersistentVolumes："
kubectl get pv
echo ""
print_info "PersistentVolumeClaims："
kubectl get pvc
echo ""
print_info "PVC 使用情況："
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName
wait_for_user

# 完成
print_header "Demo 04 完成！"
print_info "您已經學習了："
echo "  ✓ PersistentVolume (PV)：叢集級儲存資源"
echo "  ✓ PersistentVolumeClaim (PVC)：請求儲存的方式"
echo "  ✓ StorageClass：動態供應儲存的模板"
echo "  ✓ 在 Pod 和 Deployment 中使用 PVC"
echo "  ✓ 資料持久化和共享"
echo "  ✓ 不同儲存類型的使用場景"
echo ""
print_info "清理資源："
echo "  bash scripts/cleanup.sh"
echo ""
