output "vpc_id" {
  value = aws_vpc.test.id
}

output "public_subnet_1_id" {
  value = aws_subnet.pub_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.pub_2.id
}

output "private_subnet_1_id" {
  value = aws_subnet.priv_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.priv_2.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "rds_instance_id" {
  value = aws_db_instance.mysql.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend_sg.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend_sg.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "frontend_instance_id" {
  value = aws_instance.frontend.id
}

output "backend_instance_id" {
  value = aws_instance.backend.id
}

