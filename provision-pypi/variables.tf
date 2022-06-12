variable "pypi_aws_access_key_id" {
  type        = string
  description = "The key ID of the AWS account to be used by the PyPi server to save packages in S3"
}

variable "pypi_aws_access_key_secret" {
  type        = string
  description = "The secret key of the AWS account to be used by the PyPi server to save packages in S3"
}

variable "pypi_bucket_name" {
  type        = string
  description = "The bucket to be used for PyPi storage"
  default     = "lcapatina-pypi-bucket"
}