module "wiz" {
  source        = "https://s3-us-east-2.amazonaws.com/wizio-public/deployment-v2/aws/wiz-aws-native-terraform-terraform-module.zip"
  remote-arn    = "arn:aws:iam::830522659852:role/prod-us43-AssumeRoleDelegator"
  external-id   = "fc959d31-537c-4108-8b87-9af9e0c9b8d2"
  data-scanning = false
}
