The PyPi server needs an IAM account with access to the S3 bucket. 
The credentials `pypi_aws_access_key_id` and `pypi_aws_access_key_secret` can be injected through environment variables so do the following exports:
```
export TF_VAR_pypi_aws_access_key_id=xxxx
export TF_VAR_pypi_aws_access_key_secret=xxxx
```