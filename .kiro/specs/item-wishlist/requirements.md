# Requirements Document

## Project Description (Input)
グループメンバーが「欲しいアイテム」を事前にリクエスト投稿しておける機能。既存の出品アイテムへの譲渡申請（requestドメイン）とは別に、まだ出品されていないアイテムを欲しいと表明しておき、他のメンバーがそれを見て出品するきっかけとする。

## Introduction

グループ内のメンバーが「このようなアイテムが欲しい」と事前に表明できるウィッシュリスト機能。既存の `request` ドメイン（出品済みアイテムへの譲渡申請フロー）とは独立しており、まだ誰も出品していないアイテムを欲しいと発信することで、他のメンバーが出品するきっかけを提供する。

## Requirements

### Requirement 1: ウィッシュリスト投稿

**Objective:** グループメンバーとして、欲しいアイテムの情報を投稿したい。そうすることで、他のメンバーに自分のニーズを伝え、誰かが持っていれば出品してもらえるようにする。

#### Acceptance Criteria
1. When グループメンバーがタイトル・説明を入力してウィッシュリスト投稿を送信したとき, the Wishlist Service shall グループに紐づいたウィッシュリストアイテムを作成し保存する
2. If タイトルが空の場合, the Wishlist Service shall バリデーションエラーを返し投稿を拒否する
3. The Wishlist Service shall 投稿者（作成者）のユーザーIDを記録する
4. The Wishlist Service shall 投稿日時を記録する
5. If 認証済みでないユーザーがリクエストした場合, the Wishlist Service shall 401エラーを返す
6. If ユーザーが対象グループのメンバーでない場合, the Wishlist Service shall 403エラーを返す

---

### Requirement 2: ウィッシュリスト閲覧

**Objective:** グループメンバーとして、同じグループ内のウィッシュリスト一覧を見たい。そうすることで、誰が何を欲しがっているか把握し、持っているものがあれば出品できる。

#### Acceptance Criteria
1. When グループメンバーがウィッシュリスト一覧を取得したとき, the Wishlist Service shall 同一グループ内の全ウィッシュリストアイテムを返す
2. The Wishlist Service shall 各ウィッシュリストアイテムにタイトル・説明・投稿者情報・投稿日時を含める
3. The Wishlist Service shall 一覧を投稿日時の新しい順（降順）で返す
4. If ユーザーが対象グループのメンバーでない場合, the Wishlist Service shall 403エラーを返す

---

### Requirement 3: ウィッシュリスト詳細閲覧

**Objective:** グループメンバーとして、ウィッシュリストアイテムの詳細を確認したい。そうすることで、投稿内容を正確に理解し出品判断ができる。

#### Acceptance Criteria
1. When グループメンバーが特定のウィッシュリストアイテムIDを指定してリクエストしたとき, the Wishlist Service shall そのアイテムの詳細情報を返す
2. If 指定されたウィッシュリストアイテムが存在しない場合, the Wishlist Service shall 404エラーを返す
3. If ユーザーが対象グループのメンバーでない場合, the Wishlist Service shall 403エラーを返す

---

### Requirement 4: ウィッシュリスト編集

**Objective:** 投稿者として、自分が投稿したウィッシュリストアイテムを編集したい。そうすることで、内容を正確に伝えられるよう更新できる。

#### Acceptance Criteria
1. When 投稿者がタイトルまたは説明を変更して更新リクエストを送信したとき, the Wishlist Service shall ウィッシュリストアイテムを更新する
2. If 投稿者以外のユーザーが編集リクエストを送信した場合, the Wishlist Service shall 403エラーを返す
3. If タイトルが空の場合, the Wishlist Service shall バリデーションエラーを返す

---

### Requirement 5: ウィッシュリスト削除

**Objective:** 投稿者として、自分が投稿したウィッシュリストアイテムを削除したい。そうすることで、もう不要になったリクエストをグループから取り除ける。

#### Acceptance Criteria
1. When 投稿者が削除リクエストを送信したとき, the Wishlist Service shall 対象のウィッシュリストアイテムを削除する
2. If 投稿者以外のユーザーが削除リクエストを送信した場合, the Wishlist Service shall 403エラーを返す
3. If 指定されたウィッシュリストアイテムが存在しない場合, the Wishlist Service shall 404エラーを返す
