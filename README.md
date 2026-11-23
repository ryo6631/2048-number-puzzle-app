# 数字パズルゲーム iOSアプリ化プロジェクト

ブラウザ試作（数字パズルゲーム）を Capacitor で包んだ iOS アプリの土台。
ゲーム本体は `www/index.html`（試作の書き出し）。広告は `@capacitor-community/admob` を使用。

## 現在の状態
- Capacitor 6 + iOS プラットフォーム追加済み
- AdMob プラグイン組み込み済み
- ゲーム内の広告は本物 AdMob に差し替え済み（2026-11-21、www/index.html）：
  アプリとして動く時は AdMob のリワード／インタースティシャルを表示し、ブラウザでは従来のサンプル広告にフォールバックする
- www/index.html は 2026-11-21 17:59 JST 時点の試作（v11）に同期済み：ランキング、アプリ向けレイアウト、盤面と表示の重なり修正を含む。AdMob 差し替えは v11 に再適用済み（差分は AdMob 追加分のみ、JS 構文チェック済み）
- Info.plist に GADApplicationIdentifier と NSUserTrackingUsageDescription を設定済み
- 残作業：SKAdNetworkItems の正式リスト追加（リリース前）、実機での広告表示確認（ビルド環境ができてから）

## 雪屋がやること（順番に）
1. **Apple Developer Program に登録**（年99ドル）
   - https://developer.apple.com/programs/ から Apple ID で登録
2. **AdMob アカウントを作成**（無料）
   - https://admob.google.com/ でアプリを登録（iOS）
   - 広告ユニットを2つ作る：①リワード広告（復活用）②インタースティシャル（3回に1回の再スタート用）
   - 発行された「アプリID」と「広告ユニットID×2」をもちに伝える
3. **クラウドビルド用に Codemagic アカウントを作成**（無料枠あり）
   - Mac の代わりにクラウドで iOS ビルドするため

## もちがやること（IDが揃ったあと）
- ダミー広告 → 本物 AdMob 広告へ差し替え（リワード／インタースティシャル）
- アプリアイコン、スクリーンショット、プライバシーポリシーページの用意
- App Store Connect の申請情報の下書き

## AdMob ID（2026-11-21 発行済み）
- アプリID: `ca-app-pub-9487701155695176~9492598122`（capacitor.config.json に設定済み）
- リワード広告ユニットID: `ca-app-pub-9487701155695176/6422088368`（復活用）
- インタースティシャル広告ユニットID: `ca-app-pub-9487701155695176/6291719715`（3回に1回の再スタート用）

## 設定メモ
- appId（バンドルID）: `com.yukiya.numberpuzzle`（仮。App Store 登録時に確定させる）
- appName: 2048 数字パズル（2026-11-21 決定。AdMob のアプリ名にもこれを使う）
- AdMob appId は `capacitor.config.json` の plugins.AdMob.appId に記入する
