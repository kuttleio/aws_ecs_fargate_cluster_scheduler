variable account {}

variable name_prefix {
  type = string
}
variable standard_tags {
  type = map(string)
}
variable ecs_cluster {
  type = string
}
variable cloudwatch_logs_retention_in_days {
  type    = number
  default = 3
}

variable turn_on_schedule {
  description = "Turn ON Schedule"
  default     = "cron(0 8 ? * SUN-FRI *)"
}

variable turn_off_schedule {
  description = "Turn OFF Schedule"
  default     = "cron(0 20 ? * SUN-FRI *)"
}
