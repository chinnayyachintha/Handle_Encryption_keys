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

resource "aws_guardduty_invite_accepter" "accepter" {
  detector_id       = aws_guardduty_detector.payment_processing_detector.id
  master_account_id = var.aws_account_id
}

# Subscription for GuardDuty Alerts
resource "aws_sns_topic_subscription" "guardduty_subscription" {
  for_each  = toset(var.guardduty_alert_emails) # List of email addresses
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = each.value
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
