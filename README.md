# Headless Sysdig 顧客向けデモ Runbook (GKE版)

Headless Sysdig の製品デモを顧客向けに実施するための手順集です。
AI Coding Agent / MCP / API / CLI / Chat Interface を通じて、UIを開かずにクラウドセキュリティを運用する世界観を体験してもらうことを目的としています。

## ドキュメント構成

| # | ファイル | 内容 |
|---|---------|------|
| 1 | [01-demo-runbook.md](./01-demo-runbook.md) | 顧客向けデモ実施手順 (CSE向け Runbook) |
| 2 | [02-dashboard-alternative.md](./02-dashboard-alternative.md) | ダッシュボードカスタマイズ要望への代替提案 |
| 3 | [03-environment-requirements.md](./03-environment-requirements.md) | デモに必要な環境一覧 (一般) |
| 4 | [04-gke-setup.md](./04-gke-setup.md) | GKE版 Terraform Runbook |
| - | [terraform/](./terraform/) | 実行可能な Terraform コード (GKE + Sysdig Agent + Workload) |

## 環境構築フロー (明日の本番)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # project_id と sysdig_access_key を埋める
terraform init && terraform apply              # 10〜15分
```

詳細手順は [04-gke-setup.md](./04-gke-setup.md) を参照。

## デモのコアメッセージ

> **"Attackers already operate at machine speed.
> Security teams cannot continue operating at dashboard speed."**
>
> **"Headless Sysdig moves security operations from dashboards to autonomous workflows."**

## デモ成功のコツ

- **「半仕込み」が正解** — Event事前生成 / 対象固定 / Namespace固定 / Image固定 / Query固定
- **リアルタイムより再現性** を優先
- 画面比率の目安: AI Agent 70% / Terminal 20% / Sysdig UI 10%
