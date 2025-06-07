# 利用可能なアベイラビリティゾーンの情報を取得
data "aws_availability_zones" "available" {}

# アプリケーション用のVPCを作成
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # DNSホスト名を有効化
  enable_dns_support   = true  # DNS解決を有効化
  
  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# パブリックサブネットを作成（複数のAZに分散）
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)  # サブネットCIDRの数だけサブネットを作成
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]  # 配列からCIDRを順番に取得
  availability_zone       = data.aws_availability_zones.available.names[count.index]  # 利用可能なAZを順番に使用
  map_public_ip_on_launch = true  # インスタンス起動時にパブリックIPを自動割当
  
  tags = {
    Name = "${var.app_name}-public-subnet-${count.index}"  # 0から始まるインデックスをサブネット名に付与
  }
}

# プライベートサブネットを作成（複数のAZに分散）
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)  # プライベートサブネットCIDRの数だけサブネットを作成
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]  # 配列からCIDRを順番に取得
  availability_zone       = data.aws_availability_zones.available.names[count.index]  # 利用可能なAZを順番に使用
  map_public_ip_on_launch = false  # プライベートサブネットではパブリックIPを自動割当しない
  
  tags = {
    Name = "${var.app_name}-private-subnet-${count.index}"  # 0から始まるインデックスをサブネット名に付与
  }
}

# インターネットゲートウェイを作成（VPCからインターネットへの出入口）
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.app_name}-igw"
  }
}

# パブリックルートテーブルを作成（インターネットへのルーティング）
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"  # すべてのトラフィックをインターネットゲートウェイへ
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.app_name}-public-route-table"
  }
}

# プライベートルートテーブルを作成（インターネットへの直接ルーティングなし）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"  # すべてのトラフィックをインターネットゲートウェイへ
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.app_name}-private-route-table"
  }
}

# パブリックサブネットとルートテーブルを関連付け
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)  # パブリックサブネットの数だけ関連付けを作成
  subnet_id      = aws_subnet.public[count.index].id  # 対応するインデックスのサブネットを参照
  route_table_id = aws_route_table.public.id
}

# プライベートサブネットとルートテーブルを関連付け
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)  # プライベートサブネットの数だけ関連付けを作成
  subnet_id      = aws_subnet.private[count.index].id  # 対応するインデックスのサブネットを参照
  route_table_id = aws_route_table.private.id
}