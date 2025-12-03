data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

resource "aws_ec2_tag" "cluster_tag" {
  for_each = var.manage_cluster_tag ? toset(var.subnet_ids) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "elb_tag" {
  for_each = var.manage_elb_tag ? toset(var.subnet_ids) : toset([])

  resource_id = each.value
  key         = var.subnet_type == "public" ? "kubernetes.io/role/elb" : "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "custom_tags" {
  for_each = merge([
    for subnet_id in var.subnet_ids : {
      for tag_key, tag_value in var.tags :
      "${subnet_id}:${tag_key}" => {
        subnet_id = subnet_id
        key       = tag_key
        value     = tag_value
      }
    }
  ]...)

  resource_id = each.value.subnet_id
  key         = each.value.key
  value       = each.value.value
}
