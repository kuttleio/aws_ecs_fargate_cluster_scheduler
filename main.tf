data aws_region current {}

locals {
  lambda_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ],
        Resource = "*",
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.ecs_cluster
          }
        }
      }
    ]
  })
}

resource aws_iam_role cluster_scheduler_lambda_role {
  name               = "${var.name_prefix}-Cluster-Scheduler-Lambda-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.standard_tags
}

resource aws_iam_policy cluster_scheduler_lambda_policy {
  name   = "${var.name_prefix}-Cluster-Scheduler-Lambda-Policy"
  policy = local.lambda_role_policy
  tags   = var.standard_tags
}

resource aws_iam_role_policy_attachment cluster_scheduler_lambda_policy_attachment {
  role       = aws_iam_role.cluster_scheduler_lambda_role.name
  policy_arn = aws_iam_policy.cluster_scheduler_lambda_policy.arn
}

resource aws_lambda_function cluster_scheduler_turn_on {
  function_name = "${var.name_prefix}-Cluster-Scheduler-Turn-On"
  description   = "Turns ON ECS Cluster ${var.name_prefix}"
  handler       = "turn_on.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 512
  publish       = true
  filename      = "${path.module}/lambda_turn_on.zip"
  role          = aws_iam_role.cluster_scheduler_lambda_role.arn

  environment {
    variables = {
      ECS_CLUSTER = var.ecs_cluster
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.standard_tags
}

resource aws_lambda_function cluster_scheduler_turn_off {
  function_name = "${var.name_prefix}-Cluster-Scheduler-Turn-Off"
  description   = "Turns OFF ECS Cluster ${var.name_prefix}"
  handler       = "turn_off.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 512
  publish       = true
  filename      = "${path.module}/lambda_turn_off.zip"
  role          = aws_iam_role.cluster_scheduler_lambda_role.arn

  environment {
    variables = {
      ECS_CLUSTER = var.ecs_cluster
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.standard_tags
}

resource aws_cloudwatch_event_rule cluster_on {
  name                = "${var.name_prefix}-turn-on"
  description         = "Turns ON cluster: ${var.name_prefix}"
  schedule_expression = var.turn_on_schedule
  tags                = var.standard_tags
}

resource aws_cloudwatch_event_target cluster_on {
  rule = aws_cloudwatch_event_rule.cluster_on.name
  arn  = aws_lambda_function.cluster_scheduler_turn_on.arn
}

resource aws_lambda_permission cluster_on_permission {
  statement_id  = "AllowExecutionFromCloudWatchTurnOn"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cluster_scheduler_turn_on.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cluster_on.arn
}

resource aws_cloudwatch_event_rule cluster_off {
  name                = "${var.name_prefix}-turn-off"
  description         = "Turns OFF cluster: ${var.name_prefix}"
  schedule_expression = var.turn_off_schedule
  tags                = var.standard_tags
}

resource aws_cloudwatch_event_target cluster_off {
  rule = aws_cloudwatch_event_rule.cluster_off.name
  arn  = aws_lambda_function.cluster_scheduler_turn_off.arn
}

resource aws_lambda_permission cluster_off_permission {
  statement_id  = "AllowExecutionFromCloudWatchTurnOff"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cluster_scheduler_turn_off.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cluster_off.arn
}
