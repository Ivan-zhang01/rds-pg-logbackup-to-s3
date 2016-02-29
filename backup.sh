#!/bin/bash

## RDS/PostgreSQLログのバックアップスクリプト

## awscli setting
## ------------------------------
## awscli については適当に設定
## 環境に応じてプロファイル指定
#export AWS_DEFAULT_PROFILE=<****>

## 環境変数
## ------------------------------
## LOGPATH下にはディレクトリを作成しとく(mkdir logs/error -p)
RDS_INSTANCE=<RDSインスタンス名>
S3_BUCKET=<S3バケット名>
LOGPATH="<スクリプト置いたとこのパス>"

## 実行時点のログの一覧を取得
echo "RDS ${RDS_INSTANCE} のログ一覧を取得...."
LOGLIST=`aws rds describe-db-log-files --db-instance-identifier=${RDS_INSTANCE} | jq -r ".DescribeDBLogFiles[].LogFileName"`
echo "RDS ${RDS_INSTANCE} のログ一覧を取得完了"

## ログのダウンロードと、S3へのアップロードｓ
for line in ${LOGLIST}
do
  if [[ "${line}" =~ ^.*postgres.log$ ]]; then
    echo "${line} はバックアップしません"
  elif [[ "${line}" =~ ^.*postgresql.log.`date +%Y-%m-%d`-[0-9][0-9]$ ]]; then
    echo "${line} は当日のログのためバックアップしません"
  else
    ## ファイルの有無をチェック
    echo "ログファイル ${line} が、S3バケット ${S3_BUCKET} に存在するか確認"
    aws s3 ls s3://${S3_BUCKET}/${RDS_INSTANCE}/`date +%Y`/`date +%m`/${line}.gz

    ## いてなかったらファイルを落として・整形して・圧縮してアップロード
    if [ "$?" -ne 0 ]; then
      # 落として・整形(jq)・圧縮
      echo "ログファイル ${line} が、S3バケット ${S3_BUCKET} に存在しなかったので取得・整形"
      aws rds download-db-log-file-portion --db-instance-identifier=${RDS_INSTANCE} --log-file-name=${line} | jq -r "add" > ${LOGPATH}/logs/${line}
      gzip ${LOGPATH}/logs/${line}

      # アップロード
      echo "ログファイル ${line} を、S3バケット ${S3_BUCKET} にアップロード"
      aws s3 cp ${LOGPATH}/logs/${line}.gz s3://${S3_BUCKET}/${RDS_INSTANCE}/`date +%Y`/`date +%m`/${line}.gz

      # アップロード確認
      aws s3 ls s3://${S3_BUCKET}/${RDS_INSTANCE}/`date +%Y`/`date +%m`/${line}.gz
      if [ "$?" -eq 0 ]; then
        echo "ログファイル ${line} アップロードに成功しますた"
      else
        echo "ログファイル ${line} アップロードに失敗しますた"
      fi
    fi
  fi
done

## 後処理(30日前の .gz ファイルを検索して削除する)
find ${LOGPATH} -mtime 30 -type f -name \*.gz | xargs rm
