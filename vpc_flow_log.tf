###################
# Flow Log
###################
resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "REJECT"
  vpc_id          = aws_vpc.this.id
}

#####################
# Flow Log CloudWatch
#####################
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "${var.env}-${var.name}-vpc-flow-log"
  retention_in_days = 30
}

#########################
# Flow Log CloudWatch IAM
#########################
data "aws_iam_policy_document" "vpc_flow_log_trust_relationship" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vpc_flow_log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "${var.env}-${var.name}-vpc-flow-log-role"

  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_trust_relationship.json
}

resource "aws_iam_role_policy" "vpc_flow_logs_role" {
  role   = aws_iam_role.vpc_flow_log_role.name
  policy = data.aws_iam_policy_document.vpc_flow_log_policy.json
}
