# Terraform — Headless Sysdig GKE Demo

GKE クラスタ + Sysdig Agent + デモ用 Workload を Terraform で一発構築する。

## 構成

| ファイル | 役割 |
|---------|------|
| `versions.tf` | Terraform / provider のバージョン |
| `providers.tf` | google / kubernetes / helm provider 設定 |
| `variables.tf` | 入力変数 |
| `gke.tf` | GKE Standard クラスタ + Node Pool (Workload Identity 有効) |
| `sysdig.tf` | Sysdig Agent (sysdig-deploy chart) Helm リリース |
| `workloads.tf` | namespace `production` + `vulnerable-nginx` + `attacker-shell` |
| `outputs.tf` | エンドポイント / LB IP / `get-credentials` コマンド |
| `terraform.tfvars.example` | 入力サンプル (このまま `terraform.tfvars` にコピーして使う) |

## 前提

```bash
gcloud auth application-default login
gcloud config set project <your-project-id>
terraform version   # >= 1.5
helm version
```

`terraform.tfvars` を作成:

```bash
cp terraform.tfvars.example terraform.tfvars
# project_id と sysdig_access_key を埋める
```

> `terraform.tfvars` は `.gitignore` 済み。コミットしないこと。

## 実行

```bash
terraform init
terraform plan
terraform apply
```

`apply` は 10〜15 分かかる (クラスタ作成 ~7分、ノードプール ~3分、Sysdig agent ~2分)。

## 完了後

```bash
# kubectl を繋ぐ (outputs.tf の get_credentials_cmd と同じ)
gcloud container clusters get-credentials headless-demo \
  --zone asia-northeast1-a --project <your-project-id>

# 確認
kubectl get nodes
kubectl -n sysdig-agent get pods
kubectl -n production get pods,svc
```

## 削除

```bash
terraform destroy
```

> LoadBalancer の forwarding rule や disk が残っていないか念のため確認:
> ```bash
> gcloud compute forwarding-rules list
> gcloud compute disks list
> ```

## 注意点

- **`nginx:1.16` には curl/nc が入っていない** ので Runtime Event 発火は `attacker-shell` (nicolaka/netshoot) Pod から実施する
- Sysdig Agent の Helm chart のキー名は時々変わる。`apply` が失敗したら `helm show values sysdig/sysdig-deploy` で確認
- Sysdig SaaS のリージョンと collector host は必ず一致させる (`us1` ⇔ `ingest.app.sysdigcloud.com`)
- Workload Identity デモを盛り込みたい場合は別途 `google_service_account` + `iam_binding` を足す (`04-gke-setup.md` 参照)
