# 要件定義書

## はじめに

Family Marketplace は、家族・親戚間限定のクローズドなフリマアプリ（メルカリ風）。不要になった物品を出品し、招待制グループ内のメンバーだけが閲覧・申し込みできる。金銭のやり取りは行わず、商品を「譲る」形式で物品の循環を促す。外部公開はせず、プライバシーを重視したシンプルな家族向けEC体験を提供する。

対象システム: NestJS REST API（バックエンド）+ Flutter モバイルアプリ（フロントエンド）

---

## 要件

### 要件 1: ユーザー認証・招待制グループ管理

**目的:** 家族・親戚として、招待されたメンバーだけが利用できる安全なアカウント管理を行いたい。クローズドな環境でプライバシーを守りながら取引できるようにするため。

#### 受け入れ基準

1. When ユーザーが新規登録フォームに名前・パスワードを入力して送信したとき, the Family Marketplace API shall システムがランダム生成したアカウントIDとともにアカウントを作成し、JWT アクセストークンを返す
2. When ユーザーが正しいアカウントIDとパスワードでログインしたとき, the Family Marketplace API shall JWT アクセストークンおよびリフレッシュトークンを発行する
3. If 存在しないアカウントIDまたは誤ったパスワードが入力されたとき, the Family Marketplace API shall 401エラーと「アカウントIDまたはパスワードが正しくありません」メッセージを返す
4. The Family Marketplace API shall アカウントID をシステムが自動生成し、ユーザーが任意に指定できないようにする
5. When 認証済みユーザーがグループを新規作成したとき, the Family Marketplace API shall グループを生成し、作成者をオーナーメンバーとして登録する
6. When グループオーナーが招待リンクまたは招待コードを発行したとき, the Family Marketplace API shall 有効期限付きの一意な招待トークンを生成して返す
7. When 未参加ユーザーが有効な招待トークンを使用してグループ参加をリクエストしたとき, the Family Marketplace API shall そのユーザーをグループメンバーとして登録する
8. If 招待トークンが有効期限切れまたは無効なとき, the Family Marketplace API shall 400エラーと「招待リンクが無効または期限切れです」メッセージを返す
9. The Family Marketplace API shall 認証が必要なすべてのエンドポイントにおいて、有効なJWTトークンなしのリクエストを401エラーで拒否する

---

### 要件 2: 商品出品管理

**目的:** 出品者として、不要になった物品の情報（タイトル・説明・写真・渡し方）を登録・編集・削除したい。家族メンバーに正確な情報を伝えて、円滑な物品の譲渡を実現するため。

#### 受け入れ基準

1. When 認証済みユーザーがタイトル・説明・カテゴリ・渡し方オプションを含む出品データを送信したとき, the Family Marketplace API shall 商品リスティングを作成し、ステータスを「出品中」として保存する
2. When 出品者が渡し方として1つ以上のオプション（手渡し・郵送・宅配便など）を指定したとき, the Family Marketplace API shall 指定された渡し方オプションを商品に関連付けて保存する
3. When 出品者が商品に1枚以上の画像をアップロードしたとき, the Family Marketplace API shall 画像を保存し、商品リスティングに関連付ける
4. When 出品者が自分の出品情報を更新リクエストしたとき, the Family Marketplace API shall タイトル・説明・カテゴリ・渡し方オプションの変更を反映して保存する
5. If 出品者以外のユーザーが商品の編集または削除をリクエストしたとき, the Family Marketplace API shall 403エラーを返す
6. When 出品者が出品中の商品を削除したとき, the Family Marketplace API shall その商品を論理削除し、他のユーザーの一覧に表示されないようにする
7. The Family Marketplace API shall タイトルが空または200文字超、渡し方オプションが1つも指定されていないリクエストを400エラーで拒否する

---

### 要件 3: 商品一覧・詳細閲覧

**目的:** グループメンバーとして、出品されている商品を素早く見つけ、詳細を確認したい。欲しい商品を効率よく探せるようにするため。

#### 受け入れ基準

1. When 認証済みユーザーが商品一覧を取得リクエストしたとき, the Family Marketplace API shall 自分が所属するグループ内の「出品中」「取引中」ステータスの商品一覧を新着順で返す
2. When ユーザーが特定の商品IDで詳細取得リクエストしたとき, the Family Marketplace API shall タイトル・説明・カテゴリ・画像・渡し方オプション・出品者情報・ステータスを含む詳細データを返す
3. When ユーザーがキーワードで検索リクエストしたとき, the Family Marketplace API shall タイトルまたは説明にキーワードを含む商品一覧を返す
4. When ユーザーがカテゴリでフィルタリングしたとき, the Family Marketplace API shall 指定カテゴリに属する商品のみを返す
5. The Family Marketplace API shall 商品一覧APIにページネーション（offset/limit）を実装し、1リクエストあたり最大50件を返す
6. If 存在しない商品IDへのリクエストがあったとき, the Family Marketplace API shall 404エラーと「商品が見つかりません」メッセージを返す

---

### 要件 4: 取引申し込み・承認フロー

**目的:** 申し込み者として、気に入った商品に「欲しい」申し込みを送りたい。また出品者として、申し込みを承認または辞退して譲渡相手を決めたい。スムーズな家族間の物品譲渡を実現するため。

#### 受け入れ基準

1. When 認証済みユーザーが出品中の商品に申し込みリクエストを送信したとき, the Family Marketplace API shall 取引申し込みレコードを作成し、出品者にプッシュ通知を送る
2. If 出品者自身が自分の商品に申し込みリクエストを送信したとき, the Family Marketplace API shall 400エラーと「自分の出品には申し込みできません」メッセージを返す
3. If 「取引中」または「譲渡済み」ステータスの商品に申し込みリクエストが送信されたとき, the Family Marketplace API shall 409エラーと「この商品はすでに取引中または譲渡済みです」メッセージを返す
4. When 出品者が特定の申し込みを承認したとき, the Family Marketplace API shall 商品ステータスを「取引中」に更新し、申し込み者にプッシュ通知を送る
5. When 出品者が申し込みを辞退したとき, the Family Marketplace API shall 申し込みステータスを「辞退」に更新し、申し込み者にプッシュ通知を送る
6. While 商品が「取引中」のとき, the Family Marketplace API shall 他のユーザーからの新規申し込みを受け付けない
7. When 出品者または申し込み者が取引キャンセルをリクエストしたとき, the Family Marketplace API shall 商品ステータスを「出品中」に戻し、関係者にプッシュ通知を送る

---

### 要件 5: 取引完了・履歴管理

**目的:** 取引参加者として、物品の受け渡し後に取引を完了させ、過去の取引履歴を確認したい。取引の記録を残してトラブルを防ぐため。

#### 受け入れ基準

1. When 申し込み者が取引完了を報告したとき, the Family Marketplace API shall 商品ステータスを「譲渡済み」に更新し、取引完了日時を記録する
2. When 認証済みユーザーが自分の取引履歴を取得リクエストしたとき, the Family Marketplace API shall 出品・申し込みの両方の完了済み取引を日付降順で返す
3. The Family Marketplace API shall 「譲渡済み」になった商品を商品一覧から非表示にし、取引履歴からのみ参照可能にする
4. If 取引に関与していないユーザーが取引詳細へアクセスしたとき, the Family Marketplace API shall 403エラーを返す

---

### 要件 6: 商品情報シェア機能

**目的:** ユーザーとして、気になった商品の情報をLINEなど外部チャットツールへ簡単にシェアしたい。アプリ内にチャット機能を持たず、既存の家族コミュニケーションツールを活用するため。

#### 受け入れ基準

1. When ユーザーが商品詳細画面でシェアボタンをタップしたとき, the Family Marketplace App shall 商品タイトル・説明・渡し方オプション・出品者名・商品URLを含むテキストを生成し、OSのシェアシートを起動する
2. The Family Marketplace App shall シェアテキストのフォーマットを「【Family Marketplace】{タイトル}\n{説明}\n渡し方: {オプション一覧}\n出品者: {名前}」とする
3. When OSのシェアシートが起動したとき, the Family Marketplace App shall LINE・メッセージ・メール・クリップボードコピーなどOSが提供するすべての共有先を選択可能にする
4. The Family Marketplace App shall シェア機能の利用にアプリ内の認証状態は関係なく、商品詳細画面に遷移できる認証済みユーザーであれば誰でも使用できるようにする

---

### 要件 7: Flutter モバイルアプリ UI

**目的:** ユーザーとして、スマートフォンで直感的に操作できるモバイルアプリを使いたい。家族間でストレスなく不用品の出品・検索・申し込みができるようにするため。

#### 受け入れ基準

1. The Family Marketplace App shall iOS および Android の両プラットフォームで動作する
2. When アプリが起動したとき, the Family Marketplace App shall JWTトークンの有無をチェックし、未認証の場合はログイン画面を表示する
3. When ログインまたは登録が成功したとき, the Family Marketplace App shall JWTトークンをセキュアストレージに保存し、商品一覧画面に遷移する
4. When ユーザーがログイン画面でアカウントIDとパスワードを入力して送信したとき, the Family Marketplace App shall 入力値をAPIに送信し、認証結果に応じて画面を遷移する
5. When ユーザーが商品一覧を下にスクロールしたとき, the Family Marketplace App shall 次のページの商品を自動的にロードして追加表示する（無限スクロール）
6. When ユーザーが出品フォームで画像追加ボタンをタップしたとき, the Family Marketplace App shall カメラまたはフォトライブラリから画像を選択できる
7. When ユーザーが出品フォームで渡し方を設定するとき, the Family Marketplace App shall 手渡し・郵送・宅配便・その他から複数選択できるチェックボックスUIを表示する
8. If APIリクエストが失敗したとき, the Family Marketplace App shall ユーザーに分かりやすいエラーメッセージを表示し、再試行ボタンを提供する
9. While APIリクエストが処理中のとき, the Family Marketplace App shall ローディングインジケーターを表示する
