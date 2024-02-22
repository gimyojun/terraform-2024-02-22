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

// AWS 서브넷 리소스를 생성하고 이름을 'subnet_3'로 설정
resource "aws_subnet" "subnet_3" {
  // 이 서브넷이 속할 VPC를 지정. 여기서는 'vpc_1'를 선택
  vpc_id                  = aws_vpc.vpc_1.id
  // 서브넷의 IP 주소 범위를 설정
  cidr_block              = "10.0.3.0/24"
  // 서브넷이 위치할 가용 영역을 설정
  availability_zone       = "${var.region}c"
  // 이 서브넷에 배포되는 인스턴스에 공용 IP를 자동으로 할당
  map_public_ip_on_launch = true

  // 리소스에 대한 태그를 설정
  tags = {
    Name = "${var.prefix}-subnet-3"
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

resource "aws_route_table_association" "association_3" {
  subnet_id = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.rt_1.id
}

resource "aws_security_group" "sg_1" {
  name = "${var.prefix}-sg-1"
  // 인바운드 트래픽 규칙을 설정
  // 여기서는 모든 프로토콜, 모든 포트에 대해 모든 IP(0.0.0.0/0)로부터의 트래픽을 허용
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // 아웃바운드 트래픽 규칙을 설정
  // 여기서는 모든 프로토콜, 모든 포트에 대해 모든 IP(0.0.0.0/0)로의 트래픽을 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.prefix}-sg-1"
  }
}


# EC2 설정 시작

# EC2 역할 생성
resource "aws_iam_role" "ec2_role_1" {
  name = "${var.prefix}-ec2-role-1"

  # 이 역할에 대한 신뢰 정책 설정. EC2 서비스가 이 역할을 가정할 수 있도록 설정
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

# EC2 역할에 AmazonS3FullAccess 정책을 부착
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_role_1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# EC2 역할에 AmazonEC2RoleforSSM 정책을 부착
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role_1.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "instance_profile_1" {
  name = "${var.prefix}-instance-profile-1"
  role = aws_iam_role.ec2_role_1.name
}

# EC2 인스턴스 생성
resource "aws_instance" "ec2_1" {
  # 사용할 AMI ID
  ami                         = "ami-07eff2bc4837a9e01"
  # EC2 인스턴스 유형
  instance_type               = "t2.micro"
  # 사용할 서브넷 ID
  subnet_id                   = aws_subnet.subnet_1.id
  # 적용할 보안 그룹 ID
  vpc_security_group_ids      = [aws_security_group.sg_1.id]
  # 퍼블릭 IP 연결 설정
  associate_public_ip_address = true

  # 인스턴스에 IAM 역할 연결
  iam_instance_profile = aws_iam_instance_profile.instance_profile_1.name

  # 인스턴스에 태그 설정
  tags = {
    Name = "${var.prefix}-ec2-1"
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "ec2_2" {
  # 사용할 AMI ID
  ami                         = "ami-07eff2bc4837a9e01"
  # EC2 인스턴스 유형
  instance_type               = "t2.micro"
  # 사용할 서브넷 ID
  subnet_id                   = aws_subnet.subnet_3.id
  # 적용할 보안 그룹 ID
  vpc_security_group_ids      = [aws_security_group.sg_1.id]
  # 퍼블릭 IP 연결 설정
  associate_public_ip_address = true

  # 인스턴스에 IAM 역할 연결
  iam_instance_profile = aws_iam_instance_profile.instance_profile_1.name

  # 인스턴스에 태그 설정
  tags = {
    Name = "${var.prefix}-ec2-2"
  }
}