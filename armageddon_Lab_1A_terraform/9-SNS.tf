# resource "aws_sns_topic" "db_event_notification" {
#   name = "rds-event"
# }

# resource "aws_db_event_subscription" "user_updates_sns_target" {
#   topic_arn = aws_sns_topic.db_event_notification.arn
#   protocol  = "email"
#   endpoint  = "josunde15@gmail.com"
# }

# resource "aws_sns_topic" "asg_event_notification" {
#   name = "asg-event-notication"
# }

# resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
#   topic_arn = aws_sns_topic.asg_event_notification.arn
#   protocol  = "email"
#   endpoint  = "josunde15@gmail.com"
# }

# resource "aws_autoscaling_notification" "asg_actions" {
#   group_names = [
#     aws_autoscaling_group.main_asg.name,
#   ]

#   notifications = [
#     "autoscaling:EC2_INSTANCE_LAUNCH",
#     "autoscaling:EC2_INSTANCE_TERMINATE",
#     "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
#     "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
#   ]

#   topic_arn = aws_sns_topic.asg_event_notification.arn
# }


