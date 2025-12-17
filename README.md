# Kubernetes Demo 專案

這是一個完整的 Kubernetes 示範專案，涵蓋了從基礎到進階的各種資源配置範例。

## 📁 專案結構

```
k8s-demo-wb-/
├── demo/
│   ├── 01-basic/              # 基礎資源示例
│   │   ├── pod.yaml           # 基本 Pod
│   │   ├── deployment.yaml    # Deployment 部署
│   │   └── service.yaml       # Service 服務
│   │
│   ├── 02-health-checks/      # 健康檢查示例
│   │   ├── liveness.yaml      # 存活探針
│   │   ├── readiness.yaml     # 就緒探針
│   │   └── startup.yaml       # 暖機探針
│   │
│   ├── 03-advanced/           # 進階資源示例
│   │   ├── daemonset.yaml     # DaemonSet
│   │   ├── statefulset.yaml   # StatefulSet
│   │   ├── job.yaml           # Job
│   │   └── cronjob.yaml       # CronJob
│   │
│   ├── 04-storage/            # 儲存相關示例
│   │   ├── pv-pvc.yaml        # PV & PVC
│   │   └── storageclass.yaml  # StorageClass
│   │
│   └── 05-config/             # 配置管理示例
│       ├── configmap.yaml     # ConfigMap
│       └── secret.yaml        # Secret
│
├── scripts/
│   ├── demo-01-basic.sh       # 基礎示範腳本
│   ├── demo-02-health.sh      # 健康檢查示範
│   ├── demo-03-advanced.sh    # 進階功能示範
│   ├── demo-04-storage.sh     # 儲存功能示範
│   └── cleanup.sh             # 清理所有資源
│
└── README.md                  # 本文件

```

## 🚀 快速開始

### 前置需求

1. **Kubernetes 叢集** (選擇其一)：
   - 本地：Minikube / Kind / Docker Desktop
   - 雲端：AWS EKS / GKE / AKS

2. **必要工具**：
   ```bash
   # 安裝 kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   
   # 驗證安裝
   kubectl version --client
   ```

3. **連接到叢集**：
   ```bash
   # 檢查叢集連接
   kubectl cluster-info
   kubectl get nodes
   ```

## 📚 示範章節

### 第 1 章：基礎資源 (01-basic)

展示 K8S 的核心資源：Pod、Deployment、Service

```bash
# 執行基礎示範
bash scripts/demo-01-basic.sh
```

**學習重點**：
- Pod 是 K8S 最小的部署單元
- Deployment 管理 Pod 的生命週期
- Service 提供穩定的網路訪問入口

### 第 2 章：健康檢查 (02-health-checks)

展示 K8S 的自我修復能力：Liveness、Readiness、Startup Probe

```bash
# 執行健康檢查示範
bash scripts/demo-02-health.sh
```

**學習重點**：
- **Liveness Probe**：檢測應用是否存活，失敗會重啟容器
- **Readiness Probe**：檢測應用是否就緒，失敗不會接收流量
- **Startup Probe**：給應用暖機時間，成功後才啟動其他探針

### 第 3 章：進階資源 (03-advanced)

展示特殊用途的控制器

```bash
# 執行進階功能示範
bash scripts/demo-03-advanced.sh
```

**學習重點**：
- **DaemonSet**：確保每個節點運行一個 Pod
- **StatefulSet**：有狀態應用，提供穩定的網路身份
- **Job**：一次性任務
- **CronJob**：定時任務

### 第 4 章：儲存管理 (04-storage)

展示持久化儲存的使用方式

```bash
# 執行儲存功能示範
bash scripts/demo-04-storage.sh
```

**學習重點**：
- **PV (PersistentVolume)**：叢集級的儲存資源
- **PVC (PersistentVolumeClaim)**：Pod 請求儲存的方式
- **StorageClass**：動態供應儲存的模板

## 🎯 實戰演練

### 情境 1：部署一個 Web 應用

```bash
# 1. 建立 Deployment
kubectl apply -f demo/01-basic/deployment.yaml

# 2. 建立 Service 對外服務
kubectl apply -f demo/01-basic/service.yaml

# 3. 查看服務狀態
kubectl get pods
kubectl get svc

# 4. 擴展應用
kubectl scale deployment nginx-deployment --replicas=5

# 5. 查看擴展結果
kubectl get pods -w
```

### 情境 2：測試自我修復

```bash
# 1. 部署帶健康檢查的應用
kubectl apply -f demo/02-health-checks/liveness.yaml

# 2. 觀察 Pod 狀態
kubectl get pods -w

# 3. 模擬應用故障（進入容器）
kubectl exec -it <pod-name> -- rm /usr/share/nginx/html/index.html

# 4. 觀察 K8S 自動重啟容器
kubectl describe pod <pod-name>
```

### 情境 3：滾動更新與回滾

```bash
# 1. 查看當前版本
kubectl get deployment nginx-deployment -o wide

# 2. 更新映像版本
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# 3. 觀察滾動更新過程
kubectl rollout status deployment/nginx-deployment

# 4. 查看更新歷史
kubectl rollout history deployment/nginx-deployment

# 5. 回滾到上一個版本
kubectl rollout undo deployment/nginx-deployment

# 6. 回滾到指定版本
kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

## 🧹 清理資源

```bash
# 清理所有 demo 資源
bash scripts/cleanup.sh

# 或手動清理特定命名空間
kubectl delete namespace k8s-demo
```

## 📖 常用指令速查

### 查看資源

```bash
# 查看所有 Pod
kubectl get pods -A

# 查看特定 Namespace 的資源
kubectl get all -n k8s-demo

# 查看資源詳細資訊
kubectl describe pod <pod-name>

# 查看日誌
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # 持續追蹤日誌

# 查看多容器 Pod 的特定容器日誌
kubectl logs <pod-name> -c <container-name>
```

### 操作資源

```bash
# 套用配置
kubectl apply -f <yaml-file>

# 刪除資源
kubectl delete -f <yaml-file>
kubectl delete pod <pod-name>

# 進入容器
kubectl exec -it <pod-name> -- /bin/bash

# 複製檔案
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file

# 端口轉發（本地訪問服務）
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward service/<service-name> 8080:80
```

### 除錯技巧

```bash
# 查看事件
kubectl get events --sort-by=.metadata.creationTimestamp

# 查看節點資源使用
kubectl top nodes
kubectl top pods

# 檢查服務端點
kubectl get endpoints

# 檢查網路連通性
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
```

## 🎓 學習路徑建議

1. **初學者**：
   - 從 `01-basic` 開始，理解 Pod、Deployment、Service
   - 練習基本的 kubectl 指令
   - 嘗試修改 replicas 數量，觀察變化

2. **進階者**：
   - 學習 `02-health-checks`，理解自我修復機制
   - 實踐 `03-advanced`，了解不同控制器的應用場景
   - 掌握滾動更新和回滾操作

3. **實戰者**：
   - 研究 `04-storage`，理解持久化儲存
   - 使用 ConfigMap 和 Secret 管理配置
   - 嘗試在真實環境中部署應用
