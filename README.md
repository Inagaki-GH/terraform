# ECS Fargate Webアプリケーション

このTerraformコードは、AWS上にECS-Fargateでホストされたウェブアプリケーションを構築します。

## アーキテクチャ

- ECS Fargateでコンテナを実行（プライベートサブネットで実行、パブリックIPを使用）
- ALBを使用してHTTPS通信のみを許可（インターネットフェイシング）
- ACM証明書を使用したセキュアな通信
- ECRをコンテナレジストリとして使用
- コスト削減のためNATゲートウェイは不使用

## ネットワーク構成

- VPC内にパブリックサブネットとプライベートサブネットを作成
- ALBはパブリックサブネットに配置
- ECSタスクはプライベートサブネットで実行
- ECSタスクにはパブリックIPを割り当て、インターネットゲートウェイ経由で外部通信

## 前提条件

- **Route53ドメイン**: このコードを適用する前に、Route53でドメインを購入または登録し、ホストゾーンを作成しておく必要があります。
- **ドメイン設定**: `variables.tf`の`domain_name`変数に、所有しているドメイン名を設定してください。

## デプロイ手順

### 1. 初期デプロイ

```bash
# Terraformの初期化
terraform init

# 変数の設定
# variables.tfのdomain_name変数を所有しているドメインに変更

# デプロイ計画の確認
terraform plan

# インフラのデプロイ
terraform apply
```

### 2. ECRへのイメージのプッシュ

初期デプロイ後、ECRリポジトリにDockerイメージをプッシュします：

```bash
# ECRへのログイン
aws ecr get-login-password --region $(terraform output -raw aws_region) | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)

# イメージのビルドとプッシュ
docker build -t $(terraform output -raw ecr_repository_url):latest .
docker push $(terraform output -raw ecr_repository_url):latest
```

### 3. ECSサービスの更新

ECRイメージをプッシュした後、ECSタスク定義を更新します：

```bash
# variables.tfのcontainer_image変数をECRイメージに更新
# 例: "${aws_ecr_repository.app.repository_url}:latest"

# 変更を適用
terraform apply
```

## 注意事項

- 初期デプロイ時はnginx:latestイメージを使用
- 実際のアプリケーションをデプロイする前に、ECRにイメージをプッシュし、タスク定義を更新する必要があります
- セキュリティグループはHTTPS(443)のみ許可しています
- ECSタスクはプライベートサブネットで実行されますが、パブリックIPを使用してインターネットアクセスが可能です
- Route53のホストゾーンが存在しない場合、`terraform apply`はエラーになります