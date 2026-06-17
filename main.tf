# VPC

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "project-VPC"
  }
}

# Public Subnets

resource "aws_subnet" "pub_1" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pub_2" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true
}

# Private Subnets

resource "aws_subnet" "priv_1" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "priv_2" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"
}

# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test.id
}

# Elastic IP

resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_1.id

  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Public Route Tables

resource "aws_route_table" "pub_1_rt" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "pub_2_rt" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Private Route Table

resource "aws_route_table" "priv_1_rt" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Route Table Associations

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.pub_1_rt.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.pub_2_rt.id
}

resource "aws_route_table_association" "priv_1" {
  subnet_id      = aws_subnet.priv_1.id
  route_table_id = aws_route_table.priv_1_rt.id
}

resource "aws_route_table_association" "priv_2" {
  subnet_id      = aws_subnet.priv_2.id
  route_table_id = aws_route_table.priv_1_rt.id
}

# ALB Security Group

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Frontend Security Group

resource "aws_security_group" "frontend_sg" {
  name   = "frontend-sg"
  vpc_id = aws_vpc.test.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Backend Security Group

resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = aws_vpc.test.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
}

# RDS Security Group

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.test.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
}

# Load Balancer

resource "aws_lb" "alb" {
  name               = "three-tier-alb"
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = [
    aws_subnet.pub_1.id,
    aws_subnet.pub_2.id
  ]
}

# Target Group

resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test.id
}

# Listener

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# DB Subnet Group

resource "aws_db_subnet_group" "db_subnet" {
  name = "db-subnet"

  subnet_ids = [
    aws_subnet.priv_1.id,
    aws_subnet.priv_2.id
  ]
}

# RDS Instance

resource "aws_db_instance" "mysql" {
  identifier        = "college-project-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "master"
  password          = "Admin123"
  db_name           = "main"

  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
}
#EC2 Instance frontend
resource "aws_instance" "frontend" {
  ami                    = "ami-0dfb1c86c34509daf" # Amazon Linux 2 (Singapore)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pub_1.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  key_name = "keypair-ec2"

  tags = {
    Name = "Frontend-Server"
  }
}
#EC2 Instance backend
resource "aws_instance" "backend" {
  ami                    = "ami-0dfb1c86c34509daf" # Amazon Linux 2023 (Singapore)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.priv_1.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  key_name = "keypair-ec2"

  tags = {
    Name = "Backend-Server"
  }
}