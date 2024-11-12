# CloudWatch Log Group for Payment Processing API logs
resource "aws_cloudwatch_log_group" "payment_api_logs" {
  name              = "/aws/lambda/payment_processing"
  retention_in_days = 30
}

# CloudWatch Metric Alarms for Monitoring
resource "aws_cloudwatch_metric_alarm" "transaction_count_alarm" {
  alarm_name          = "${var.project_name}-TransactionCountAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "TransactionCount"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Alert if transactions exceed the threshold."
}

resource "aws_cloudwatch_metric_alarm" "error_rate_alarm" {
  alarm_name          = "${var.project_name}-ErrorRateAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorRate"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert if error rate is high."
}

resource "aws_cloudwatch_metric_alarm" "high_latency_alarm" {
  alarm_name          = "${var.project_name}-HighLatencyAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Latency"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Average"
  threshold           = 2000 # Latency threshold in milliseconds
  alarm_description   = "Alert if API latency is high."
}

# Enable CloudTrail for API Monitoring
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

# Server-side encryption configuration for CloudTrail logs bucket
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
  }
}

# Enable GuardDuty for Threat Detection
resource "aws_guardduty_detector" "payment_processing_detector" {
  enable = true
}

# SNS Topic for GuardDuty Alerts
resource "aws_sns_topic" "guardduty_alerts" {
  name = "${var.project_name}-GuardDutyAlerts"
}

# Subscription for GuardDuty Alerts
resource "aws_sns_topic_subscription" "guardduty_subscription" {
  for_each  = toset(var.guardduty_alert_emails)
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# CloudWatch Event to Trigger GuardDuty Findings Notification
resource "aws_cloudwatch_event_rule" "guardduty_findings_rule" {
  name        = "GuardDutyFindingsRule"
  description = "Trigger notification for GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"],
    "detail-type" = ["GuardDuty Finding"],
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings_rule.name
  arn       = aws_sns_topic.guardduty_alerts.arn
  target_id = "GuardDutyFindingsTarget"
}

# CloudWatch Dashboard for Real-Time Monitoring
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
          "region" : var.region,
          "stat" : "Sum",
          "period" : 300,
          "title" : "Payment Processing Metrics"
        }
      }
    ]
  })
}

# SNS Topic for Alarm Notifications
resource "aws_sns_topic" "alarm_notifications" {
  name = "${var.project_name}-AlarmNotifications"
}

# SNS Subscription for Alarm Notifications
resource "aws_sns_topic_subscription" "alarm_email_subscription" {
  for_each  = toset(var.alarm_notification_emails)
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# Attach SNS topic to CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "high_error_rate_alarm" {
  alarm_name          = "${var.project_name}-HighErrorRateAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorRate"
  namespace           = "PaymentProcessing"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert if error rate is high."
  alarm_actions       = [aws_sns_topic.alarm_notifications.arn]
}
