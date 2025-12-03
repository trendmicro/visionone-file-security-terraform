output "tagged_subnet_ids" {
  description = "List of subnet IDs that have been tagged"
  value       = [for subnet in data.aws_subnet.selected : subnet.id]
}


output "subnet_details" {
  description = "Details of tagged subnets"
  value = {
    for id, subnet in data.aws_subnet.selected : id => {
      id                = subnet.id
      availability_zone = subnet.availability_zone
      cidr_block        = subnet.cidr_block
      vpc_id            = subnet.vpc_id
    }
  }
}
