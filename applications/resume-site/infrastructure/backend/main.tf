# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

resource "aws_dynamodb_table" "visitor_counter" {
  name           = "visitor-counter"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
