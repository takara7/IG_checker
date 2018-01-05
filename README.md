Instagramの特定のユーザーの投稿をスクレイピングして、ツイッターに投稿します。

## 必要なもの
mac or UNIX or Linux
Ruby 2.4以降
Twitter gem

## 使い方
1. Twitter APIの登録
1. 設定ファイルを登録
1. Rubyがなければインストール
1. gemのインストール
1. cronに登録

### Twitter APIの登録
Twitterでアプリケーション登録をして、アクセストークンを取得してください。（[参照](https://syncer.jp/Web/API/Twitter/REST_API/)）
- Consumer key
- Consumer secret
- Access token
- Access token secret

の4つが必要です。

### 設定ファイルを登録
config.yamlをテキストエディタで開いて編集します。

ここには先ほど取得したconsumer_keyやaccess_tokenと、監視対象のInstagramアカウントを設定します。
対象のアカウントはいくつでも設定可能です。
`name`を設定すると、ツイートが「名前：本文 URL」のような形式になります。省略すると「名前：」の部分がなくなります。
```yaml:config.yaml
consumer_key: <取得したconsumer_key>
consumer_secret: <取得したconsumer_secret>
access_token: <取得したaccess_token>
access_token_secret: <取得したaccess_token_secret>

users:
  - id: 監視対象のアカウントのid(1)
    name: アカウントの名前（省略可）
  - id: 監視対象のアカウントのid(2)
    name: アカウントの名前（省略可）
```

### Rubyのインストール
macなら標準で入ってるとは思いますが、たぶん1.8とかなので古くて動きません。
インストール方法は調べれば腐るほど見つかるので省略

### gemのインストール
Twitterに投稿するためのライブラリをインストールします。
シェルで以下のコマンドを叩いてください。
```shell-session
$ gem install bundler
$ bundle install
```

### cronに登録
`$ crontab -e`で、run_checker.shとlog_rotation.shを設定します。
`run_checker.sh`は.bash_profileや.bashrcを読み込むので、そこでPATHの設定をしてください（cronのデフォルトは/usr/local/binなどが入っていません）。
`log_rotation.sh`は1か月ごとにログファイルのローテーションを行う前提で書いているので、毎月1日に動かすのがいいと思います。
