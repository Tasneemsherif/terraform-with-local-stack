# --- VPC & NETWORKING ---

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# We need public subnets for our Load Balancer and NAT Gateway
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az2"
  }
}

# Private subnets for EC2 Instances and RDS
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-az1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-az2"
  }
}

# --- ROUTING & NAT GATEWAY (The "Shield" icon) ---

# NAT Gateway for private subnets to access the internet
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "main-nat-gw"
  }

  # Depends on the IGW being attached
  depends_on = [aws_internet_gateway.gw]
}

# Public route table (routes to Internet)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Private route table (routes to NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Associate route tables
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# --- SECURITY GROUPS ---

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow HTTP/S traffic to LB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
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

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow traffic from LB and EFS"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from the load balancer
  ingress {
    description     = "HTTP from LB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow SSH from anywhere (for testing - ideally lock this down)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS traffic from EC2 instances"
  vpc_id      = aws_vpc.main.id

  # Allow NFS from our EC2 instances
  ingress {
    description     = "NFS from EC2"
    from_port       = 2049 # NFS port
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL traffic from EC2 instances"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL from our EC2 instances
  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- LOAD BALANCER (ALB) ---

resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

resource "aws_lb_target_group" "main" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# --- FIREWALL (WAF) ---
# This represents the pink firewall icon
resource "aws_wafv2_web_acl" "main" {
  name  = "main-waf-acl"
  scope = "REGIONAL" # Use REGIONAL for ALB

  default_action {
    allow {}
  }

  # Add some rules here if you want
  # rule { ... } 

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "main-waf"
    sampled_requests_enabled   = false
  }

  tags = {
    Name = "main-waf"
  }
}

# Associate WAF with the Load Balancer
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}


# --- EFS (The "Elastic" Pink Icon) ---

resource "aws_efs_file_system" "main" {
  creation_token = "my-efs"
  tags = {
    Name = "main-efs"
  }
}

resource "aws_efs_mount_target" "az1" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.private_az1.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "az2" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.private_az2.id
  security_groups = [aws_security_group.efs_sg.id]
}

# --- EC2 KEY PAIR (The "Key" Icon) ---

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}

# --- EC2 AUTO SCALING GROUP ---

resource "aws_launch_template" "main" {
  name                   = "main-lt"
  image_id               = var.ec2_ami
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # User data to install a web server and mount EFS
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html

    # Mount EFS
    sudo yum install -y amazon-efs-utils
    sudo mkdir /mnt/efs
    sudo mount -t efs ${aws_efs_file_system.main.id}:/ /mnt/efs
    # Add to fstab for persistence
    echo "${aws_efs_file_system.main.id}:/ /mnt/efs efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
    EOF
  )
}

resource "aws_autoscaling_group" "main" {
  name                = "main-asg"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Attach to the LB target group
  target_group_arns = [aws_lb_target_group.main.arn]
}

# --- RDS DATABASE (The "R" Icon) ---

resource "random_string" "db_password" {
  length  = 16
  special = false
  upper = false
}

resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  tags = {
    Name = "Main DB subnet group"
  }
}

resource "aws_db_instance" "main" {
  identifier           = "main-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "14.5"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "admin"
  password             = random_string.db_password.result
  db_subnet_group_name = aws_db_subnet_group.main.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  # The problematic provisioner block has been removed from here.
}

# --- S3 BUCKET ---

resource "aws_s3_bucket" "main" {
  bucket = "my-localstack-demo-bucket-${random_string.db_password.id}" # Unique name
}

# --- ROUTE 53 (DNS) ---

resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}