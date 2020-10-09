output "mysql_dns" {
  value = [aws_instance.awsqa_mysql.*.public_dns]
}

output "spark_dns" {
  value = [aws_instance.awsqa_spark.*.public_dns]
}

