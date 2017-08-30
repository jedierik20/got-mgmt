variable "billing_api_server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

variable "billing_api_cluster_name" {
  description = "The name to use for all the cluster resources"
}

#variable "db_remote_state_bucket" {
#  description = "The name of the S3 bucket for the database's remote state"
#}

#variable "db_remote_state_key" {
#  description = "The path for the database's remote state in S3"
#}

variable "billing_api_instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
}


###
#  Not yet using an ASG (Auto Scaling Group) for Billig-api
#
#variable "billing_api_asg_min_size" {
#  description = "The minimum number of EC2 Instances in the ASG"
#}

#variable "billing_api_asg_max_size" {
#  description = "The maximum number of EC2 Instances in the ASG"
#}
