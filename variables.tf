# AWS Region where resources will be deployed
variable "aws_region" {
  type        = string
  description = "AWS Region to deploy resources"
}

# Project Name
variable "project_name" {
  type        = string
  description = "Name of the project"
}

# Stage Name
variable "stage_name" {
  type        = string
  description = "Name of the stage"
}

# AWS Account ID
variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

# Email addresses to subscribe to GuardDuty alerts SNS topic
variable "guardduty_alert_emails" {
  description = "List of email addresses to subscribe to GuardDuty alerts SNS topic"
  type        = list(string)
}

# Email addresses to subscribe to Alarm notifications SNS topic
variable "alarm_notification_emails" {
  description = "List of email addresses to subscribe to Alarm notifications SNS topic"
  type        = list(string)
}