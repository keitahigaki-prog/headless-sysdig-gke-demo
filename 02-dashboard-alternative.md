# ダッシュボードカスタマイズ要望への代替提案

「カスタムダッシュボードを作りたい」という顧客要望に対して、Headless Sysdig の世界観を提案するためのストーリーです。

> Headless Sysdig は、
> 「ダッシュボードを頑張って作り込む世界」から、
> 「必要な情報を AI / API / Workflow 経由で動的に取得する世界」
> への転換として見せると、非常に刺さります。

特に Kubernetes / CNAPP は:
- 欲しい情報が毎回変わる
- インシデントごとに観点が変わる
- 固定ダッシュボードがすぐ陳腐化する

ので、そこを問題提起にできます。

---

## 提案すべきストーリー

### タイトル例

- **「Dashboard-less Security Operations」**
- **「固定ダッシュボードから動的セキュリティ運用へ」**

### 顧客課題として整理

#### 顧客が言っていること
「カスタムダッシュボードを作りたい」

#### 本当の課題
- 欲しい情報が毎回変わる
- Runtime / Vulnerability / CSPM が分断
- Kubernetes metadata が複雑
- インシデントごとに見る軸が違う
- UIで drill down が大変

### そこで Headless を提案

> 「固定ダッシュボードを増やす」のではなく、
> 「必要な視点をその場でAIに生成させる」

---

## プレゼン構成

| セクション | 内容 |
|-----------|------|
| 1 | 現状のダッシュボード運用の限界 |
| 2 | Kubernetes時代の問題 |
| 3 | なぜ固定UIが限界なのか |
| 4 | Headless Securityとは |
| 5 | Live Demo |
| 6 | 今後の運用イメージ |

---

## 1. 現状の問題提起

### 従来

- ダッシュボードを作る
- Widgetを並べる
- 監視項目を固定化
- Drill Down
- 別画面へ遷移
- さらに検索

↓

### 結果

**「情報を見るためのUI運用」になっている。**

---

## 2. Kubernetes時代の限界

### Kubernetesでは

調査したい単位が毎回違う。

- 今日は: namespace
- 明日は: workload
- 次は: image digest
- さらに: service account / runtime event / exposed workload / CVE / internet exposure

毎回違う。

### つまり

**固定Dashboardでは追いつかない。**

---

## 3. Headless の価値

### 従来
「事前にDashboardを設計」

↓

### Headless
「必要な視点をその場で生成」

---

## 4. ここでデモ

### 超オススメ

Cursor や Claude Code を使う。めちゃくちゃ未来感が出る。

### デモ例

#### ケース1

```
Show me internet exposed workloads with critical vulnerabilities running in production.
```

**顧客が驚くポイント:**
これ普通は Vulnerability画面 / Exposure画面 / Kubernetes metadata / Runtime inventory を横断する必要がある。

#### ケース2

```
Show me runtime threats related to curl or wget executions in the last 24 hours.
```

#### ケース3

```
Which workloads are generating the highest number of runtime alerts?
```

#### ケース4 (重要)

```
Summarize the security posture of the payments namespace.
```

---

## 5. ここで刺さる言葉

### 超重要

> 「ダッシュボードを作る」のではなく、
> **「問い合わせ可能なセキュリティプラットフォーム」になる。**

### さらに強い言い方

- 従来: **Dashboard-driven Security**
- Headless: **Context-driven Security** または **Query-driven Security**

---

## 6. Runtimeを絡める

これが Sysdig らしさ。Wizとの差別化。

単なるGraph Queryではなく:
- Runtime context
- Live workload
- Process execution
- Falco events

が入る。

### ここで言う

> **"Runtime turns static posture into operational context."**

これはかなり強い。

---

## 7. 顧客に刺さる締め

### かなりおすすめ

> 「ダッシュボードを増やすほど、運用は複雑になる。」

↓

> **「Headlessは、必要な情報を必要な瞬間に生成する。」**

---

## 8. 最後に提案する方向性

「Dashboard customization」要求に対して:

### 従来案
- Widget追加
- カスタム画面
- 保存ビュー
- Drilldown改善

### 新しい提案
- AI-driven investigation
- Dynamic query
- Runtime-aware context
- Workflow automation
- Headless operations

---

## 一番重要なポイント

これは「UIを捨てる話」ではありません。

本質は:

> **「固定化された運用を減らす」**

です。

ここを丁寧に説明すると、日本企業でもかなり理解されます。
