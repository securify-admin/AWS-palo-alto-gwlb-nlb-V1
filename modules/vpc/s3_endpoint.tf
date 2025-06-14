# Create an S3 VPC endpoint if enabled
resource "aws_vpc_endpoint" "s3" {
  count             = var.create_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  
  # Explicitly associate with all route tables to ensure S3 access during bootstrap
  route_table_ids = concat(
    [aws_route_table.public_rt.id],
    var.create_private_rt ? [aws_route_table.private_rt[0].id] : [],
    [for rt in aws_route_table.custom_rt : rt.id]
  )
  
  tags = {
    Name = "${var.vpc_name}-s3-endpoint"
  }
}
