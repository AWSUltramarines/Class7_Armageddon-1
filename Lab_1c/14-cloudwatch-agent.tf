# # --- CloudWatch Agent config stored in SSM Parameter ---
# resource "aws_ssm_parameter" "cw_agent_config" {
#   name  = "/lab/cloudwatch/agent-config"
#   type  = "String"
#   value = jsonencode({
#     logs = {
#       logs_collected = {
#         files = {
#           collect_list = [
#             # system logs (good baseline)
#             {
#               file_path      = "/var/log/messages"
#               log_group_name = var.app_log_group_name
#               log_stream_name = "{instance_id}/messages"
#               timezone       = "UTC"
#             },
#             # if your app logs to a file, add it here (recommended)
#             # {
#             #   file_path      = "/var/log/rdsapp.log"
#             #   log_group_name = var.app_log_group_name
#             #   log_stream_name = "{instance_id}/rdsapp"
#             #   timezone       = "UTC"
#             # }
#           ]
#         }
#       }
#     }
#   })
# }

# # --- Allow EC2 to run SSM + publish logs to CloudWatch ---
# resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_role_policy_attachment" "ec2_cw_agent" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

# # --- Install + configure the CloudWatch Agent via SSM Association ---
# # Target your instance(s) by tag. Set this tag on your EC2 instance:  LabRole=web
# resource "aws_ssm_association" "install_configure_cw_agent" {
#   name = "AmazonCloudWatch-ManageAgent"

#   targets {
#     key    = "tag:LabRole"
#     values = ["web"]
#   }

#   parameters = {
#     action                        = "Install"
#     mode                          = "ec2"
#     optionalConfigurationSource   = "ssm"
#     optionalConfigurationLocation = aws_ssm_parameter.cw_agent_config.name
#     optionalRestart               = "yes"
#   }
# }
