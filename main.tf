terraform {
  // 자바의 import 와 비슷함
  // aws 라이브러리 불러옴
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

// AWS VPC(Virtual Private Cloud) 리소스를 생성하고 이름을 'vpc_1'로 설정
resource "aws_vpc" "vpc_1" {
  // VPC의 IP 주소 범위를 설정
  cidr_block = "10.0.0.0/16"

  // DNS 지원을 활성화
  enable_dns_support   = true
  // DNS 호스트 이름 지정을 활성화
  enable_dns_hostnames = true

  // 리소스에 대한 태그를 설정
  tags = {
    Name = "${var.prefix}-vpc-1"
  }
}

// AWS 서브넷 리소스를 생성하고 이름을 'subnet_1'로 설정
resource "aws_subnet" "subnet_1" {
  // 이 서브넷이 속할 VPC를 지정. 여기서는 'vpc_1'를 선택
  vpc_id                  = aws_vpc.vpc_1.id
  // 서브넷의 IP 주소 범위를 설정
  cidr_block              = "10.0.1.0/24"
  // 서브넷이 위치할 가용 영역을 설정
  availability_zone       = "${var.region}a"
  // 이 서브넷에 배포되는 인스턴스에 공용 IP를 자동으로 할당
  map_public_ip_on_launch = true

  // 리소스에 대한 태그를 설정
  tags = {
    Name = "${var.prefix}-subnet-1"
  }
}

// AWS 서브넷 리소스를 생성하고 이름을 'subnet_2'로 설정
resource "aws_subnet" "subnet_2" {
  // 이 서브넷이 속할 VPC를 지정. 여기서는 'vpc_1'를 선택
  vpc_id                  = aws_vpc.vpc_1.id
  // 서브넷의 IP 주소 범위를 설정
  cidr_block              = "10.0.2.0/24"
  // 서브넷이 위치할 가용 영역을 설정
  availability_zone       = "${var.region}b"
  // 이 서브넷에 배포되는 인스턴스에 공용 IP를 자동으로 할당
  map_public_ip_on_launch = true

  // 리소스에 대한 태그를 설정
  tags = {
    Name = "${var.prefix}-subnet-2"
  }
}

resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id
  tags = {
    Name = "${var.prefix}-igw-1"
  }
}
// aws 라우트 테이블 리소스를 생성하고 이름을 rt_1로 설정
resource "aws_route_table" "rt_1" {
  vpc_id = aws_vpc.vpc_1.id
// 라우트 규칙을 설정. 모든 트래픽(0.0.0.0/0)을 igw_1 인터넷 게이트웨이로 보냄
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name = "${var.prefix}-rt-1"
  }

}

resource "aws_route_table_association" "association_1" {
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt_1.id
}


resource "aws_route_table_association" "association_2" {
  subnet_id = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.rt_1.id
}