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