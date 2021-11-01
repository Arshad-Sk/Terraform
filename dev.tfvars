configuration = [
  {
    "application_name" : "Master",
    "ami" : "ami-074cce78125f09d61",
    "no_of_instances" : "1",
    "instance_type" : "t2.medium",
   # "vpc_security_group_ids" : ["aws_security_group.awssg.id"]
     
  },
  {
    "application_name" : "Slave",
    "ami" : "ami-074cce78125f09d61",
    "instance_type" : "t2.micro",
    "no_of_instances" : "2"
   # "vpc_security_group_ids" : ["aws_security_group.awssg.id"]
  }
  
]




