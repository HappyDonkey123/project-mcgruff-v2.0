resource "aws_db_subnet_group" "database" {
  name = var.application_database_name

  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = var.application_database_name
  }
}

resource "aws_security_group" "database" {
  name   = var.application_database_name
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = var.application_database_name
  }
}

resource "aws_vpc_security_group_egress_rule" "database_egress" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "database_ingress" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
}

resource "aws_db_instance" "database" {
  identifier             = var.application_database_name
  storage_type           = "gp2"
  allocated_storage      = 10
  multi_az               = false
  availability_zone      = "us-east-1a"
  db_name                = "wordpress"
  db_subnet_group_name   = aws_db_subnet_group.database.id
  engine                 = "mariadb"
  engine_version         = "10.11"
  instance_class         = "db.t3.micro"
  port                   = "3306"
  publicly_accessible    = false
  username               = "administrator"
  password               = "Cisco!123"
  parameter_group_name   = "default.mariadb10.11"
  apply_immediately      = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [ aws_security_group.database.id ]
  depends_on = [
    module.vpc,
    aws_db_subnet_group.database,
    aws_security_group.database
  ]
}
