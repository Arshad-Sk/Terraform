configuration = [
  {
    "application_name" : "Master",
    #"ami" : "ami-074cce78125f09d61",
    #"ami" : "ami-07d7bc8b24fd4c585",
     "ami": "ami-02df5cb5ad97983ba",
    "no_of_instances" : "1",
    "instance_type" : "t3.medium",
   # "vpc_security_group_ids" : ["aws_security_group.awssg.id"]
     
  },
  {
    "application_name" : "Slave",
    #"ami" : "ami-074cce78125f09d61",
    #"ami" : "ami-07d7bc8b24fd4c585",
      "ami": "ami-02df5cb5ad97983ba",
     "instance_type" : "t3.micro",
    "no_of_instances" : "2"
   # "vpc_security_group_ids" : ["aws_security_group.awssg.id"]
  }  
]




