# Setting up CloudWatch Log Groups and Custom Metrics
# To monitor API requests, Lambda functions, and key metrics, 
# CloudWatch Log Groups and custom metrics are used

# Define CloudWatch Log Group for Payment Processing API logs
resource "aws_cloudwatch_log_group" "payment_api_logs" {
  name              = "/aws/lambda/payment_processing"
  retention_in_days = 30
}

# CloudWatch Metric for Transaction Count
resource "aws_cloudwatch_metric_alarm" "transaction_count_alarm" {
  alarm_name          = "${var.project_name}-TransactionCountAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "TransactionCount"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Alert if transactions exceed the threshold, indicating a spike in transactions."
}

# Error Rate Alarm (e.g., for Lambda function)
resource "aws_cloudwatch_metric_alarm" "error_rate_alarm" {
  alarm_name          = "${var.project_name}-ErrorRateAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorRate"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert if error rate is high, indicating potential processing issues."
}

# Latency Alarm
resource "aws_cloudwatch_metric_alarm" "high_latency_alarm" {
  alarm_name          = "${var.project_name}-HighLatencyAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Latency"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Average"
  threshold           = 2000 # Latency threshold in milliseconds
  alarm_description   = "Alert if API latency exceeds the acceptable threshold."
}

# Configuring CloudTrail for API Monitoring
# CloudTrail logs API calls, focusing on critical services like AWS KMS, Lambda, and Secrets Manager.

# Enable CloudTrail for API monitoring
resource "aws_cloudtrail" "payment_processing_trail" {
  name                          = "${var.project_name}-CloudTrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}

# Get current account id
data "aws_caller_identity" "current" {}


# S3 Bucket to store CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "${var.project_name}-cloudtrail-logs"
}

# Server-side encryption configuration for the CloudTrail logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy to allow CloudTrail to write logs
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.bucket

  policy = data.aws_iam_policy_document.cloudtrail_policy.json
}

# Define the CloudTrail bucket policy document
data "aws_iam_policy_document" "cloudtrail_policy" {
  statement {
    actions   = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = [
        "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"
      ]
    }
  }
}

# Enabling GuardDuty for Threat Detection
# GuardDuty analyzes VPC Flow Logs, CloudTrail events, and DNS logs to detect unusual activity.

# Enable GuardDuty for Threat Detection
resource "aws_guardduty_detector" "payment_processing_detector" {
  enable = true
}

# Create notifications for GuardDuty findings
resource "aws_sns_topic" "guardduty_alerts" {
  name = "${var.project_name}-GuardDutyAlerts"
}

# Accept GuardDuty invitation from the master account
resource "aws_guardduty_invite_accepter" "accepter" {
  detector_id       = aws_guardduty_detector.payment_processing_detector.id
  master_account_id = var.aws_account_id
  accept_invitation = true  # Make sure to accept the invitation
}

# Subscription for GuardDuty Alerts
resource "aws_sns_topic_subscription" "guardduty_subscription" {
  for_each  = toset(var.guardduty_alert_emails) # List of email addresses
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# Add GuardDuty finding notifications to SNS topic
resource "aws_guardduty_member" "member" {
  detector_id     = aws_guardduty_detector.payment_processing_detector.id
  account_id      = var.aws_account_id
  email           = var.guardduty_alert_email
  status          = "ENABLED"
  invite          = false
  master_account_id = var.aws_account_id  # Optional: Set to the master account ID if needed
}

# Configure CloudWatch Event to trigger notifications on GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings_rule" {
  name        = "GuardDutyFindingsRule"
  description = "Trigger notification for GuardDuty findings"

  event_pattern = jsonencode({
    source = ["aws.guardduty"],
    detail-type = ["GuardDuty Finding"],
  })
}

# CloudWatch Event Target to send alerts to SNS topic
resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings_rule.name
  arn       = aws_sns_topic.guardduty_alerts.arn
  target_id = "GuardDutyFindingsTarget"
}

# Allow CloudWatch Events to publish to SNS
resource "aws_lambda_permission" "allow_sns_publish" {
  statement_id  = "AllowSNSPublish"
  action        = "lambda:InvokeFunction"
  function_name = aws_cloudwatch_event_target.send_to_sns.target_id
  principal     = "sns.amazonaws.com"
}


# CloudWatch Dashboard for Real-Time Monitoring
# This dashboard displays the key metrics, providing an overview of transaction counts, latency, and error rates.

# Create a CloudWatch Dashboard for Real-time Monitoring
resource "aws_cloudwatch_dashboard" "payment_processing_dashboard" {
  dashboard_name = "${var.project_name}-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["PaymentProcessing", "TransactionCount"],
            ["PaymentProcessing", "ErrorRate"],
            ["PaymentProcessing", "Latency"]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "us-west-2",
          "stat" : "Sum",
          "period" : 300,
          "title" : "Payment Processing Metrics"
        }
      }
    ]
  })
}


# Alerting with SNS Notifications
# Configure SNS to notify the DevOps or Security team when alarms are triggered.

# SNS Topic for Alarms
resource "aws_sns_topic" "alarm_notifications" {
  name = "${var.project_name}-AlarmNotifications"
}

# SNS Subscription for Alarm Notifications
resource "aws_sns_topic_subscription" "alarm_email_subscription" {
  for_each  = toset(var.alarm_notification_emails) # List of email addresses
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# Attach SNS topic to CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate_alarm" {
  alarm_name          = "${var.project_name}-HighErrorRateAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorRate"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert if the error rate is high."
  alarm_actions       = [aws_sns_topic.alarm_notifications.arn]
}
