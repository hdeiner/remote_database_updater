resource "aws_security_group" "mysql_awsqa" {
  name        = "MySQL AWSQA Security Group"
  description = "MySQL AWSQA Security Group"
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  ingress {
    protocol  = "tcp"
    from_port = 3306
    to_port   = 3306
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "AWSQA MySQL Security Group"
  }
}

