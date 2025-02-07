
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Create public subnet (needed for public IP access)
resource "aws_subnet" "public_subnet-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet 1"
  }
}

resource "aws_subnet" "public_subnet-2" {

    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch =   true

    tags = {
      "Name" = "Public-Subnet 2"
    }

  
}
# Create private subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-2"
  }
}

# Create security group for Web Servers

resource "aws_security_group" "websrv_sg" {

    vpc_id = aws_vpc.main.id

    ingress = [

        {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]

        },

        {
            description = "Allow HTTP"
            from_port   = 80
            to_port     = 80
            protocol    = "HTTP"
            cidr_blocks = ["0.0.0.0/0"]
        },

        {
            description = "Allow HTTPS"
            from_port   = 443
            to_port     = 443
            protocol    = "HTTPS"
            cidr_blocks = ["0.0.0.0/0"]
        }

 ]

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Websrv-security-group"
  }
}

# Create security group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# Create RDS DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "my-db-subnet-group"
  }
}


# Create RDS MySQL Instance
resource "aws_db_instance" "database" {
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  engine                 = "mysql"
  engine_version         = "8.0.34"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "password123"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  tags = {
    Name = "mydb-instance"
  }
}

# Create a Web Server EC2 Instance
resource "aws_instance" "web_server" {
  ami                  = "ami-0c614dee691cbbf37"  # Updated AMI ID
  instance_type        = "t2.micro"
  subnet_id           = aws_subnet.public_subnet-1.id  # Use public subnet for public IP
  associate_public_ip_address = true  # Assign public IP
  vpc_security_group_ids = [aws_security_group.websrv_sg.id] # Corrected argument name
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              echo "Welcome to Venkat's Webpage" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOF
  
  tags = {
    Name = "web-server-instance"
  }
}