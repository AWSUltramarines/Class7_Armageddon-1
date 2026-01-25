################################
#### Route53
################################
variable "domain_name" {
  description = "The domain name for the Route53 Hosted Zone"
  type        = string
}
################################
#### Load Balancer
################################
variable "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  type        = string
}
variable "alb_zone_id" {
  description = "The Hosted Zone ID of the Application Load Balancer"
  type        = string
}
