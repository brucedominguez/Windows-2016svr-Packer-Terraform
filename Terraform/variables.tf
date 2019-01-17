variable "aws_region" {
  description = "Set aws region"
  default = "ap-southeast-2"
}

variable "aws_profile" {
  description = "Set the aws cli profile to use"
  default = "ADD PROFILE HERE"
}
variable "name_tag" {
  description = "Set the Name Tag used for filtering specific VPC and Security Groups"
  default = "ADD_TAG"
}

variable "instance" {
  description = "Set Instance type e.g T3.medium"
  default = "t2.medium"

}

variable "iam_role" {
  description = "IAM Role to be used"
  default = "ADD_ROLE"
}

variable "volume_type" {
  description = "The type of volume. Can be standard gp2 or io1 or sc1st1"
  default = "standard"
}

variable "volume_size" {
  description = "size of the ebs volume needed"
  default = "50"
}

variable "key_name" {
  description = "name given to the SSH keys"
  default = "KEY_NAME_YOU_WANT_TO_USE"
}
