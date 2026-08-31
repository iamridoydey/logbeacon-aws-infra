[admin]
${instance_id}

[admin:vars]
# Let the ansilbe know to use ssm for signin
ansible_connection=amazon.aws.aws_ssm
ansible_aws_ssm_region=${aws_region}
ansible_aws_ssm_bucket_name=${ssm_bucket_name}
ansible_python_interpreter=/usr/bin/python3