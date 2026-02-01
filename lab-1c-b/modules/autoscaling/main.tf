resource "aws_autoscaling_group" "dev_asg" {
  name_prefix               = var.asg_name
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_size
  vpc_zone_identifier       = [var.public_subnet_ids[0], var.public_subnet_ids[1]]
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_hc_grace_period
  force_delete              = true

  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]

  # Instance protection for launching
  initial_lifecycle_hook {
    name                  = "instance-protection-launch"
    lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
    default_result        = "CONTINUE"
    heartbeat_timeout     = 60
    notification_metadata = "{\"key\":\"value\"}"
  }

  # Instance protection for terminating
  initial_lifecycle_hook {
    name                 = "scale-in-protection"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
  }

  tag {
    key                 = "Name"
    value               = "dev-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Production"
    propagate_at_launch = true
  }
}


# Auto Scaling Policy
resource "aws_autoscaling_policy" "dev_scaling_policy" {
  name                   = "${var.name_prefix}-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.dev_asg.name

  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.asg_policy_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

# Enabling instance scale-in protection
resource "aws_autoscaling_attachment" "dev_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.dev_asg.name
  lb_target_group_arn    = var.target_group_arn
}