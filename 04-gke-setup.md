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

## Step 6: バックエンド検証 (Sysdig UI でデータ着信確認)

Headless はUIを使わない世界観だが、**デモ前にバックエンドにデータが届いているかだけ** UI で確認する。確認できれば UI はもう開かない。

### URL ルール

Sysdig Secure はハッシュルーティング。`/secure/#/<path>` 形式。`/<path>` 直打ちは 404。

US West (us2) tenant の例:

| 確認したいもの | URL / メニュー |
|---------------|---------------|
| Cluster が認識されている | `https://us2.app.sysdig.com/secure/#/inventory` → cluster filter で `headless-demo` |
| Agent が Up to Date | Settings → Sysdig Agent (or Integrations → Agent Inventory) |
| Runtime Event が届いている | Detection & Response → Events / Insights |
| Vulnerability スキャン完了 | Vulnerabilities → Findings → Runtime (5〜10分かかる) |
| Sysdig Sage が有効 | `https://us2.app.sysdig.com/secure/#/sage-agentic` でページが開ける |

### Sysdig Sage の有効化 (Headless プラグインの前提条件)

Headless Cloud Security Public Beta の前提として **Sysdig Sage が有効化されている必要がある**。

Sysdig 社員アカウント (@sysdig.com) なら Internal Features から以下のフラグを ON:

- `New Sysdig Sage Agentic Module` (必須)
- `Sysdig Sage | Next` (推奨)
- `Widgets in Sysdig Sage` (デモ映え用)
- `Graph Search | Enable SysQL V3-alpha` (バックボーン)
- `Integrations Hub` (将来 MCP 設定が入る可能性)

---

## Step 7: Claude Code + sysdig-skills プラグイン導入

> **公式サポートランタイムは Claude Code のみ** (2026-05-12 時点)。
> Cursor / その他の MCP 互換 Agent は理論上動くが launch 時点で非サポート。
>
> 公式 GitHub: https://github.com/sysdig/skills
> 紹介ブログ: https://www.sysdig.com/blog/introducing-headless-cloud-security

### Skill 一覧

`headless-cloud-security` プラグインには5つの Skill が入っている:

| Skill | 用途 | デモ対応 |
|-------|------|---------|
| `sysdig-investigate` | Vulnerability 調査・優先順位付け・remediation plan | Demo 1 |
| `sysdig-runtime-investigate` | Falco runtime threat 分析・脆弱性との相関 | Demo 2 |
| `sysdig-remediate` | 脆弱イメージ修正・PR/MR 自動作成 | Demo 3 |
| `sysdig-onboarding` | AWS / K8s onboarding (Terraform/Helm) | 補足 |
| `sysdig-posture` | Rego / Posture policy 作成 | 補足 |

### Step 7.1: API Token 取得

Sysdig UI → **Settings → Sysdig API** → **新規 API Token を発行**してコピー。

### Step 7.2: 環境変数を設定

```bash
# 一時的 (この shell だけ)
export SYSDIG_SECURE_URL=https://us2.app.sysdig.com
export SYSDIG_SECURE_API_TOKEN=<paste-token>

# 永続化したいなら、.zshrc ではなく専用ファイルが安全:
mkdir -p ~/.config/sysdig
cat > ~/.config/sysdig/env <<'EOF'
export SYSDIG_SECURE_URL=https://us2.app.sysdig.com
export SYSDIG_SECURE_API_TOKEN=<paste-token>
EOF
chmod 600 ~/.config/sysdig/env
# その後使うときは: source ~/.config/sysdig/env
```

### Step 7.3: プラグインインストール

Claude Code を環境変数を入れた shell から起動して、以下のスラッシュコマンドを実行:

```
/plugin marketplace add sysdig/skills
/plugin install headless-cloud-security@sysdig-skills
```

その後 **Claude Code を再起動**。

### Step 7.4: 接続確認

新セッションで軽いクエリ:

```
List Kubernetes clusters connected to Sysdig.
```

応答が返ってくれば OK。

### デモ用クエリ (本番)

#### Demo 1: Vulnerability Investigation (`sysdig-investigate`)
```
Show me critical vulnerabilities affecting running containers in the production namespace,
and prioritize by runtime exposure.
```

#### Demo 2: Runtime Threat Investigation (`sysdig-runtime-investigate`)
```
Investigate the latest runtime threat in the production namespace.
Correlate with image vulnerabilities and show the process tree.
```

#### Demo 3: Remediation (`sysdig-remediate`)
```
Generate remediation steps for the vulnerable-nginx workload
and open a PR with the fix.
```

#### Posture summary
```
Summarize the security posture of the headless-demo cluster.
```

---

## Step 8: GKE固有で刺さる話 — Workload Identity

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

## Step 9: クリーンアップ

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

## 詰まったとき (実測ベース)

| 症状 | 原因 / 確認ポイント |
|------|------------------|
| `terraform apply` が helm 段階で固まる | Node Pool 完成後 helm 走るか / pods が Pending or CrashLoop か `kubectl -n sysdig-agent get pods` |
| 全 Pod が Pending、`Insufficient cpu` | **machine_type が小さすぎる**。`e2-standard-2` では 2vCPU で agent + node-analyzer (4コンテナ) の request に足りない → `e2-standard-4` 以上にする |
| Agent ログに `ERR_INVALID_CUSTOMER_KEY (Unauthorized agent access key)` | **テナントのリージョン違い** が最有力。Sysdig UI の URL で実際のリージョンを確認 (例: `us2.app.sysdig.com` なら `region = "us2"` / `collector_host = "ingest-us2.app.sysdig.com"`) |
| Agent ログに `Could not resolve <collector hostname>` | collector ホスト名がそのリージョンに存在しない。下表参照 |
| `node-analyzer` の `sysdig-benchmark-runner` だけ CrashLoopBackOff | テナントに Compliance/Benchmark 機能が未開放。デモには影響しないので無視可 |
| Runtime event が UI に出ない | Falco rules enabled か / namespace filter / 30秒〜2分のラグ |
| `kubectl exec` で `bash: command not found` | netshoot ではなく違う image。`sh` にフォールバック |
| `nginx:1.16` で curl したい | **入っていないので無理**。`attacker-shell` を使う |
| `/sage-agentic` が 404 | Sysdig Secure はハッシュルーティング。`/secure/#/sage-agentic` が正解 |
| Sage Agentic 画面が "No remediable images" のまま | Vulnerability スキャン未完了 or 環境フィルタ。**Headless デモ的にはこのUIは見せない** (Claude Code から触る) |
| `terraform destroy` で kubernetes resource エラー | API が先に消えると state 不整合。`terraform state rm` で逃がす |

### Sysdig SaaS リージョン早見表

| Region | UI URL | region code | Collector |
|--------|--------|-------------|-----------|
| US East (N. Virginia) | `app.sysdigcloud.com` | `us1` | `collector.sysdigcloud.com` |
| US West (Oregon) | `us2.app.sysdig.com` | `us2` | `ingest-us2.app.sysdig.com` |
| US West GCP | `app.us4.sysdig.com` | `us4` | `ingest.us4.sysdig.com` |
| EU | `eu1.app.sysdig.com` | `eu1` | `ingest.eu1.app.sysdig.com` |
| AP Sydney | `app.au1.sysdig.com` | `au1` | `ingest.au1.app.sysdig.com` |

> **「US East 」と聞いてもまず UI URL を確認すること。** Region 名は誤伝されがち。

---

## チェックリスト (デモ当日朝)

### インフラ
- [ ] `terraform apply` 完了 (10〜15分)
- [ ] `kubectl get nodes` で 2 Ready (e2-standard-4)
- [ ] `kubectl -n sysdig-agent get pods` で agent 1/1 Running、node-analyzer 3/4 (benchmark-runner だけ Crash は許容)
- [ ] LoadBalancer の external IP が取れている (exposure 話に使う)

### Sysdig バックエンド
- [ ] Inventory に cluster `headless-demo` が見える
- [ ] Agent Inventory が **Up to Date** (両ノード)
- [ ] `vulnerable-nginx` の脆弱性 (CVE) が UI に出ている (5〜10分かかる)
- [ ] Runtime Event を1個だけ事前に発火して UI に出ることを確認
- [ ] `New Sysdig Sage Agentic Module` フラグが ON で `/secure/#/sage-agentic` が開ける

### Headless / Claude Code
- [ ] API Token 発行済み
- [ ] `SYSDIG_SECURE_URL` / `SYSDIG_SECURE_API_TOKEN` env var が export 済み
- [ ] `/plugin install headless-cloud-security@sysdig-skills` 完了
- [ ] Claude Code 再起動後に簡単クエリ (`List clusters`) が通る

### 撤収
- [ ] `terraform destroy` コマンドを別ターミナルに開いておく
