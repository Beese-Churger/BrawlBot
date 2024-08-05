resource "aws_vpc" "lambda_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "brawlbot_vpc"
  }
}

resource "aws_subnet" "private-lambda" {
  cidr_block = var.private_subnet_cidr
  vpc_id     = aws_vpc.lambda_vpc.id
  tags = {
    Name = "brawlbot_private_subnet"
  }
}

resource "aws_subnet" "public-lambda" {
  cidr_block = var.public_subnet_cidr
  vpc_id     = aws_vpc.lambda_vpc.id
  tags = {
    Name = "brawlbot_public_subnet"
  }
}

resource "aws_eip" "lambdas" {
  domain = "vpc"
  tags = {
    Name = "brawlbot_eip"
  }
}

resource "aws_internet_gateway" "intgw" {
  vpc_id = aws_vpc.lambda_vpc.id
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.lambdas.id
  subnet_id     = aws_subnet.public-lambda.id
}

resource "aws_route_table" "private-lambda" {
  vpc_id = aws_vpc.lambda_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
}

resource "aws_route_table_association" "private-lambda" {
  route_table_id = aws_route_table.private-lambda.id
  subnet_id      = aws_subnet.private-lambda.id
}

resource "aws_route_table" "public-lambda" {
  vpc_id = aws_vpc.lambda_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.intgw.id
  }
}

resource "aws_route_table_association" "public-lambda" {
  route_table_id = aws_route_table.public-lambda.id
  subnet_id      = aws_subnet.public-lambda.id
}

resource "aws_security_group" "allow_tls" {
  depends_on  = [aws_vpc.lambda_vpc]
  name        = "allow_ls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.lambda_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
