resource "aws_ecs_cluster" "main" {
  name = "${var.name}-${var.env}-cluster"
}
resource "aws_iam_role" "ecs_task_role" {
  name                = "${var.name}-ecsTaskRole"
  managed_policy_arns = [aws_iam_policy.cognito.arn, aws_iam_policy.invoke_lambda.arn, aws_iam_policy.app-mesh-envoy.arn, aws_iam_policy.xray.arn, "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser", "arn:aws:iam::aws:policy/AmazonKinesisFullAccess", "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess", "arn:aws:iam::aws:policy/CloudWatchFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess"]
  assume_role_policy  = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "invoke_lambda" {
  name   = "${var.short_name}-invoke_lambda"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Invoke",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "xray" {
  name = "${var.short_name}-xray"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords",
                "xray:GetSamplingRules",
                "xray:GetSamplingTargets",
                "xray:GetSamplingStatisticSummaries"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_policy" "app-mesh-envoy" {
  name   = "${var.short_name}-mesh_envoy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "appmesh:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "arn:aws:iam::*:role/aws-service-role/appmesh.amazonaws.com/AWSServiceRoleForAppMesh",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": [
                        "appmesh.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStack*",
                "cloudformation:UpdateStack"
            ],
            "Resource": "arn:aws:cloudformation:*:*:stack/AWSAppMesh-GettingStarted-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "acm-pca:DescribeCertificateAuthority",
                "acm-pca:ListCertificateAuthorities"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicediscovery:ListNamespaces",
                "servicediscovery:ListServices",
                "servicediscovery:ListInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cognito" {
  name   = "${var.short_name}-cognito-super-user"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cognito-identity:*",
                "cognito-idp:*",
                "cognito-sync:*",
                "iam:ListRoles",
                "iam:ListOpenIdConnectProviders",
                "sns:ListPlatformApplications",
                "iam:GetRole",
                "iam:ListOpenIDConnectProviders",
                "iam:ListRoles",
                "iam:ListSAMLProviders",
                "iam:GetSAMLProvider",
                "kinesis:ListStreams",
                "lambda:GetPolicy",
                "lambda:ListFunctions",
                "sns:ListPlatformApplications",
                "ses:ListIdentities",
                "ses:GetIdentityVerificationAttributes",
                "mobiletargeting:GetApps",
                "acm:ListCertificates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "cognito-idp.amazonaws.com",
                        "email.cognito-idp.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:DeleteServiceLinkedRole",
                "iam:GetServiceLinkedRoleDeletionStatus"
            ],
            "Resource": [
                "arn:aws:iam::*:role/aws-service-role/cognito-idp.amazonaws.com/AWSServiceRoleForAmazonCognitoIdp*",
                "arn:aws:iam::*:role/aws-service-role/email.cognito-idp.amazonaws.com/AWSServiceRoleForAmazonCognitoIdpEmail*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name                = "${var.name}-ecsTaskExecutionRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy", aws_iam_policy.s3.arn, aws_iam_policy.ecr.arn, "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess", "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_policy" "s3" {
  name = "${var.short_name}-s3_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "ecr" {
  name = "${var.short_name}-ecr_read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
