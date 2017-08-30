output "billing_api_alb_dns_name" {
  value = "${aws_alb.billing_api.dns_name}"
}

output "billing_api_asg_name" {
  value = "${aws_autoscaling_group.billing_api.name}"
}

output "billing_api_alb_security_group_id" {
  value = "${aws_security_group.alb.id}"
}
