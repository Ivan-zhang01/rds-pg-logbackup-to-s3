
やっつけ仕事

#### 使い方

1. ログを保管するためのS3バケットを作成
2. IAMユーザ/ポリシーの作成と割り当て
  - 上記S3バケットへのアクセス権
  - DescribeDBLogFiles
  - DownloadDBLogFilePortion
3. 実行するEC2インスタンスでawscliの設定と、jqのインストール  
4. スクリプトを設置して中身の書き換えとかディレクトリの作成とか
5. cron などで適当に回す

