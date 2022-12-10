resource "aws_iam_role" "website_dlm_lifecycle_role" {
  name = "website-dlm-lifecycle-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "website_dlm_lifecycle_role_policy" {
  name = "website-dlm-lifecycle-role-policy"
  role = aws_iam_role.website_dlm_lifecycle_role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}

resource "aws_dlm_lifecycle_policy" "website_dlm_lifecycle_policy" {
  description        = "the DLM lifecycle policy of the website"
  execution_role_arn = aws_iam_role.website_dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"]

    schedule {
      name = "Daily AMI Backup"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["00:00"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        AMICreator = "DLM"
      }
    }

    target_tags = {
      backup = "true"
    }
  }
}
