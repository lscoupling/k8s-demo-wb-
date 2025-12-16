#!/bin/bash

# Demo 03: 進階資源示範
# 展示 DaemonSet、StatefulSet、Job、CronJob

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

print_header "K8S Demo 03: 進階資源示範"

# 1. DaemonSet
print_header "步驟 1: DaemonSet 示範"
print_info "DaemonSet 確保每個節點運行一個 Pod"
print_info "常用於：日誌收集、監控代理、網路插件"
echo ""
print_info "部署 DaemonSet..."
kubectl apply -f demo/03-advanced/daemonset.yaml
print_info "等待 DaemonSet 就緒..."
sleep 10
print_info "\n查看 DaemonSet："
kubectl get daemonsets
print_info "\n查看 DaemonSet 的 Pods（每個節點一個）："
kubectl get pods -l app=fluentd -o wide
print_info "\n節點數量："
kubectl get nodes --no-headers | wc -l
print_info "DaemonSet Pods 數量："
kubectl get pods -l app=fluentd --no-headers | wc -l
wait_for_user

# 2. DaemonSet 詳細資訊
print_header "步驟 2: DaemonSet 詳細資訊"
print_info "查看 node-exporter DaemonSet："
kubectl get daemonset node-exporter -o wide
print_info "\n查看 Pods 分佈："
kubectl get pods -l app=node-exporter -o wide
print_info "\n查看 DaemonSet 的 Tolerations（容忍度）："
kubectl get daemonset fluentd-daemonset -o jsonpath='{.spec.template.spec.tolerations}' | python3 -m json.tool
wait_for_user

# 3. StatefulSet
print_header "步驟 3: StatefulSet 示範"
print_info "StatefulSet 用於有狀態應用"
print_info "特點："
echo "  • 穩定的網路身份（固定的 Pod 名稱）"
echo "  • 穩定的持久化儲存"
echo "  • 有序的部署和縮放"
echo ""
print_info "部署 StatefulSet..."
kubectl apply -f demo/03-advanced/statefulset.yaml
print_info "等待 StatefulSet 就緒..."
sleep 15
print_info "\n查看 StatefulSet："
kubectl get statefulsets
print_info "\n查看 Pods（注意名稱是有序的）："
kubectl get pods -l app=nginx-stateful
wait_for_user

# 4. StatefulSet 網路身份
print_header "步驟 4: StatefulSet 網路身份"
print_info "StatefulSet 的每個 Pod 都有穩定的 DNS 名稱"
print_info "格式：<pod-name>.<service-name>.<namespace>.svc.cluster.local"
echo ""
print_info "查看 Headless Service："
kubectl get svc nginx-stateful-service
print_info "\n測試 Pod 的 DNS 解析："
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup nginx-stateful-0.nginx-stateful-service || print_warning "DNS 測試完成"
wait_for_user

# 5. StatefulSet 持久化儲存
print_header "步驟 5: StatefulSet 持久化儲存"
print_info "每個 Pod 都有自己的 PVC"
print_info "\n查看 PVCs："
kubectl get pvc
print_info "\n查看每個 Pod 的掛載資訊："
for pod in $(kubectl get pods -l app=nginx-stateful -o name); do
    echo "---"
    print_info "Pod: $pod"
    kubectl exec $pod -- cat /usr/share/nginx/html/index.html 2>/dev/null || echo "  內容未就緒"
done
wait_for_user

# 6. StatefulSet 有序部署
print_header "步驟 6: StatefulSet 擴展示範"
print_info "StatefulSet 的擴展是有序的"
print_info "\n當前副本數："
kubectl get statefulset nginx-stateful -o jsonpath='{.spec.replicas}'
echo ""
print_info "\n擴展到 5 個副本..."
kubectl scale statefulset nginx-stateful --replicas=5
print_info "觀察有序創建過程："
kubectl get pods -l app=nginx-stateful -w &
WATCH_PID=$!
sleep 20
kill $WATCH_PID 2>/dev/null || true
print_info "\n\n擴展後的 Pods："
kubectl get pods -l app=nginx-stateful
wait_for_user

# 7. Job
print_header "步驟 7: Job 示範"
print_info "Job 用於一次性任務"
print_info "任務完成後，Pod 會保留以供查看日誌"
echo ""
kubectl apply -f demo/03-advanced/job.yaml
print_info "等待 Job 完成..."
sleep 15
print_info "\n查看 Jobs："
kubectl get jobs
print_info "\n查看 Job 的 Pods："
kubectl get pods -l app=job-demo
wait_for_user

# 8. Job 日誌
print_header "步驟 8: 查看 Job 輸出"
print_info "查看簡單 Job 的日誌："
JOB_POD=$(kubectl get pods -l job-name=simple-job -o jsonpath='{.items[0].metadata.name}')
kubectl logs $JOB_POD
echo ""
print_info "\n查看資料處理 Job 的日誌："
DATA_JOB_POD=$(kubectl get pods -l app=data-processor -o jsonpath='{.items[0].metadata.name}')
kubectl logs $DATA_JOB_POD 2>/dev/null || print_warning "Job 可能還在執行中"
wait_for_user

# 9. 並行 Job
print_header "步驟 9: 並行 Job 示範"
print_info "parallel-job 會創建多個 Pod 並行處理任務"
print_info "\n查看並行 Job："
kubectl get job parallel-job -o wide
print_info "\n查看 Job 進度："
kubectl get job parallel-job -o jsonpath='Completions: {.status.succeeded}/{.spec.completions}, Active: {.status.active}'
echo ""
print_info "\n查看並行執行的 Pods："
kubectl get pods -l app=job-demo,type=parallel
wait_for_user

# 10. CronJob
print_header "步驟 10: CronJob 示範"
print_info "CronJob 按照 Cron 表達式定時執行任務"
kubectl apply -f demo/03-advanced/cronjob.yaml
print_info "\n查看 CronJobs："
kubectl get cronjobs
print_info "\n查看 CronJob 詳細資訊："
kubectl get cronjob simple-cronjob -o wide
wait_for_user

# 11. CronJob 執行記錄
print_header "步驟 11: CronJob 執行記錄"
print_info "等待 CronJob 執行（simple-cronjob 每分鐘執行一次）..."
print_warning "這可能需要等待約 60 秒"
sleep 70
print_info "\n查看由 CronJob 創建的 Jobs："
kubectl get jobs -l app=cronjob-demo
print_info "\n查看最近的執行日誌："
LATEST_JOB=$(kubectl get jobs -l app=cronjob-demo --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
if [ ! -z "$LATEST_JOB" ]; then
    CRONJOB_POD=$(kubectl get pods -l job-name=$LATEST_JOB -o jsonpath='{.items[0].metadata.name}')
    print_info "Job: $LATEST_JOB, Pod: $CRONJOB_POD"
    kubectl logs $CRONJOB_POD
else
    print_warning "還沒有執行記錄"
fi
wait_for_user

# 12. CronJob 排程說明
print_header "步驟 12: CronJob 排程配置"
echo "查看不同的 CronJob 排程："
echo ""
kubectl get cronjobs -o custom-columns=NAME:.metadata.name,SCHEDULE:.spec.schedule,LAST-SCHEDULE:.status.lastScheduleTime
echo ""
echo "Cron 表達式說明："
echo "  */1 * * * *  - 每分鐘"
echo "  0 2 * * *    - 每天 02:00"
echo "  15 * * * *   - 每小時的第 15 分"
echo "  0 9 * * 1    - 每週一 09:00"
echo "  */5 * * * *  - 每 5 分鐘"
wait_for_user

# 13. 資源摘要
print_header "步驟 13: 進階資源摘要"
print_info "DaemonSets："
kubectl get daemonsets
echo ""
print_info "StatefulSets："
kubectl get statefulsets
echo ""
print_info "Jobs："
kubectl get jobs
echo ""
print_info "CronJobs："
kubectl get cronjobs
echo ""
print_info "PersistentVolumeClaims："
kubectl get pvc
wait_for_user

# 完成
print_header "Demo 03 完成！"
print_info "您已經學習了："
echo "  ✓ DaemonSet：在每個節點運行 Pod"
echo "  ✓ StatefulSet：管理有狀態應用"
echo "  ✓ StatefulSet 的穩定網路身份和持久化儲存"
echo "  ✓ Job：執行一次性任務"
echo "  ✓ 並行 Job：同時執行多個任務"
echo "  ✓ CronJob：定時執行任務"
echo ""
print_info "清理資源："
echo "  bash scripts/cleanup.sh"
echo ""
print_info "下一個示範："
echo "  bash scripts/demo-04-storage.sh"
echo ""
