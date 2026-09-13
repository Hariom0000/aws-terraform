# Security group controlling database access boundaries
resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-postgres-sg"
  description = "Allow inbound PostgreSQL traffic from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id] # Direct structural bridge to EKS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-postgres-sg" }
}

# Grouping subnets across multiple AZs for the database cluster
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.data_subnet_ids
  tags       = { Name = "${var.environment}-db-subnet-group" }
}

# The PostgreSQL DB Engine Instance
resource "aws_db_instance" "postgres" {
  identifier                  = "${var.environment}-postgres"
  allocated_storage           = 20
  max_allocated_storage       = 100
  engine                      = "postgres"
  engine_version              = "15.4"
  instance_class              = "db.t4g.micro" # Free tier eligible/low-cost burstable type
  db_name                     = "appdb"
  username                    = "dbadmin"
  manage_master_user_password = true # AWS automatically handles password management via Secrets Manager

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true # Set to false for actual production environments

  tags = { Environment = var.environment }
}