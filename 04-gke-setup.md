# GKE版 Headless Sysdig デモ構成 — Terraform Runbook

> 上から順番に実行すれば動く。GKE / Sysdig Agent / デモ用 Workload はすべて Terraform で構築する。
> Runtime Event 発火 (`kubectl exec`) と Cursor/MCP 接続だけ手動。
>
> 想定: GKE Standard (asia-northeast1-a, zonal, 2ノード) + Sysdig Secure (US East) + Cursor/Claude Code。

---

## 全体像

```
[Cursor / AI Agent]
        ↓
   MCP / API
        ↓
[Sysdig Secure SaaS — US East]
        ↓
[GKE Cluster (asia-northeast1-a)]   ← Terraform で構築
   ├─ vulnerable-nginx       (脆弱性表示用)
   ├─ attacker-shell         (Runtime Event発火用)
   ├─ sysdig-agent           (Helm via Terraform)
   └─ GCP CSPM connector     (オプション)
```

実体は [`terraform/`](./terraform/) ディレクトリ。

---

## 前提

| 項目 | 値 |
|------|----|
| GCP Project | `<your-project-id>` |
| GKE Zone | `asia-northeast1-a` (zonal) |
| Node | `e2-standard-2` × 2 |
| Sysdig Region | **US East** (`app.sysdigcloud.com`) |
| Sysdig region短縮形 | `us1` |
| Collector endpoint | `ingest.app.sysdigcloud.com` |
| AI Agent | Cursor or Claude Code |

> Sysdig SaaS の **agent access key** と **API token** を事前に取得する。
> Sysdig UI → **Settings → Sysdig Agent** (access key) / **Sysdig API** (API token)。

---

## Step 0: ローカル準備

```bash
# gcloud
gcloud auth login
gcloud auth application-default login          # Terraform が使う ADC
gcloud config set project <your-project-id>

# 必要API (Terraform でも有効化するが、初回apply前に手動でやっておくと安全)
gcloud services enable container.googleapis.com compute.googleapis.com

# 道具
terraform version       # >= 1.5
helm version
kubectl version --client
```

---

## Step 1: Terraform で一括構築

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して project_id と sysdig_access_key を入れる

terraform init
terraform plan
terraform apply
```

`apply` の所要時間: 10〜15分。

### 完了したら kubectl を接続

```bash
gcloud container clusters get-credentials headless-demo \
  --zone asia-northeast1-a --project <your-project-id>

kubectl get nodes
```

`Ready` のノード 2 個が見えればOK。

### Sysdig Agent 起動確認

```bash
kubectl -n sysdig-agent get pods
kubectl -n sysdig-agent logs -l app=sysdig-agent --tail=50 | grep -i "Connected\|collector"
```

`Connected to collector` が出ていればOK。

### Sysdig UI 側で確認

UI → **Inventory** または **Kubernetes → Clusters** に `headless-demo` が現れるまで 2〜3分待つ。

---

## Step 2: デモ用 Workload 確認

Terraform で既にデプロイ済み。確認だけ:

```bash
kubectl -n production get pods,svc
```

期待:
- `vulnerable-nginx` Deployment + LoadBalancer Service (External IP 取得まで 1〜2分)
- `attacker-shell` Pod (`Running`)

External IP は `terraform output vulnerable_nginx_lb_ip` でも確認可。

---

## Step 3: Vulnerability スキャン待ち

Sysdig Runtime Scanner がイメージスキャンを走らせる。5〜10分待つ。

確認場所: Sysdig UI → **Vulnerabilities → Runtime → Filter: cluster=headless-demo, namespace=production**

`nginx:1.16` に対して Critical/High が並んでいればOK。

---

## Step 4: Runtime Event 発火

> 全部 **attacker-shell** Pod 内で実行する。Falco デフォルトルールで確実に光るやつ。
> `nginx:1.16` には curl/nc が入っていないので使わない (重要)。

```bash
kubectl -n production exec -it attacker-shell -- bash
```

### Event 1: Read sensitive file (`Read sensitive file untrusted`)

```bash
cat /etc/shadow
```

### Event 2: Write below etc (`Write below etc`)

```bash
echo "demo" > /etc/demo-marker
```

### Event 3: Launch suspicious network tool (`Launch Suspicious Network Tool in Container`)

```bash
curl -s http://example.com > /dev/null
```

### Event 4: Package management in container (`Launch Package Management Process in Container`)

```bash
apt-get update 2>&1 | head -3
```

### Event 5 (オプション)

```bash
history -c
```

### Pod から抜ける

```bash
exit
```

### 検証

Sysdig UI → **Events** または **Insights → Runtime** で、上記イベントを確認。
*出るまでに30秒〜2分のラグあり。*

---

## Step 5: GCP CSPM 連携 (オプション、時間あれば)

Sysdig UI → **Integrations → Cloud accounts → Add GCP** から、Terraform script で連携。
Sysdig 公式の Terraform module が提供されているはずなので、必要なら別 state で `cd ../terraform-gcp-cspm` を切る。

連携後に見せられるもの:
- Public exposure (LoadBalancer)
- IAM / Service Account
- Bucket exposure
- GKE posture findings

---

## Step 6: Cursor + MCP 接続

### MCP 設定

Cursor の `~/.cursor/mcp.json` (またはClaude Code の設定) に Sysdig MCP server を追加。

```json
{
  "mcpServers": {
    "sysdig": {
      "command": "<sysdig mcp server command>",
      "env": {
        "SYSDIG_API_TOKEN": "<your token>",
        "SYSDIG_ENDPOINT": "https://app.sysdigcloud.com"
      }
    }
  }
}
```

> 実際のコマンド/設定は Sysdig Headless プレビュー資料の手順に従う。
> 接続確認: Cursor 内で軽いクエリで応答が返るか試す。

### デモ用クエリ (本番で打つやつ)

#### Runtime系
```
Investigate the latest runtime threat in production namespace.
```

#### Vulnerability系
```
Show critical vulnerabilities affecting running workloads.
```

#### Exposure系
```
Which internet exposed workloads have critical CVEs?
```

#### Kubernetes系
```
Summarize the security posture of the production namespace.
```

---

## Step 7: GKE固有で刺さる話 — Workload Identity

GKE は **Workload Identity** で Kubernetes Service Account ↔ GCP IAM Service Account を紐付けられる。
Terraform の `gke.tf` で `workload_identity_config` 有効化済み + Node Pool で `GKE_METADATA` モード設定済み。

Headless でこう聞ける:

```
Which workloads in headless-demo cluster have Workload Identity bindings,
and what GCP IAM permissions do those service accounts hold?
```

→ GKE 顧客に対して「Pod単位の権限可視化」を見せる強いネタになる。

### 危ない構成を仕込みたい場合 (時間あれば追加)

別途 Terraform で:

```hcl
resource "google_service_account" "demo_overprivileged" {
  account_id = "demo-overprivileged"
}

resource "google_project_iam_member" "demo_overprivileged" {
  project = var.project_id
  role    = "roles/editor"   # 意図的に強い権限
  member  = "serviceAccount:${google_service_account.demo_overprivileged.email}"
}

resource "google_service_account_iam_member" "wi_binding" {
  service_account_id = google_service_account.demo_overprivileged.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[production/overprivileged-app]"
}

resource "kubernetes_service_account" "overprivileged_app" {
  metadata {
    name      = "overprivileged-app"
    namespace = "production"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.demo_overprivileged.email
    }
  }
}
```

これで AI に「過剰権限 GSA に紐付いてる workload を探して」と聞くと拾える。

---

## Step 8: クリーンアップ

> **GKE クラスタは課金が走るので、デモ後は必ず削除する。**

```bash
cd terraform
terraform destroy
```

`destroy` 後に念のため確認:

```bash
gcloud compute forwarding-rules list
gcloud compute disks list
```

LoadBalancer / Disk が残っていたら個別に削除。

---

## 詰まったとき

| 症状 | 確認ポイント |
|------|------------|
| `terraform apply` が helm 段階で固まる | Node Pool が完成してから helm 走ってるか / `kubectl get nodes` |
| Agent が `CrashLoopBackOff` | `helm get values -n sysdig-agent sysdig-agent` で access key / region / collector を確認 |
| UI に cluster が出ない | Agent ログに `Connected to collector` が出ているか / Sysdig テナントのリージョン違い |
| Runtime event が UI に出ない | Falco rules が enabled か / namespace filter / 30秒〜2分のラグ |
| `kubectl exec` で `bash: command not found` | netshoot ではなく違う image。`sh` にフォールバック |
| `nginx:1.16` で curl したい | **入っていないので無理**。`attacker-shell` を使う |
| `terraform destroy` で kubernetes resource エラー | API が先に消えると state 不整合。`terraform state rm` で逃がす |

---

## チェックリスト (デモ当日朝)

- [ ] `terraform apply` 完了 (10〜15分)
- [ ] `kubectl get nodes` で 2 Ready
- [ ] `kubectl -n sysdig-agent get pods` で DaemonSet Running
- [ ] Sysdig UI に cluster `headless-demo` が見える
- [ ] `vulnerable-nginx` の脆弱性が UI に出ている (5〜10分かかる)
- [ ] Runtime Event を1個だけ事前に発火して UI に出ることを確認
- [ ] Cursor から MCP 経由でクエリが通る
- [ ] LoadBalancer の external IP が取れている (exposure 話に使う)
- [ ] `terraform destroy` コマンドを別ターミナルに開いておく
