provider "aws"  {
         
   # region = "us-east-1"
     region = "eu-north-1"
     
   
}
variable "access_key" {}
variable "secret_key" {}


locals {
  serverconfig = [
    for srv in var.configuration : [
      for i in range(1, srv.no_of_instances+1) : {
        instance_name = "${srv.application_name}-${i}"
        instance_type = srv.instance_type
        tag_name = srv.application_name
       # subnet_id   = srv.subnet_id
        ami = srv.ami
        security_groups = [aws_security_group.awssg_jkn.id]
        #vpc_security_group_ids = [aws_security_group.awssg_jkn.id]
        # sparkkey_jkn = [aws_key_pair.awskey]
      }
    ]
  ]
}
// We need to Flatten it before using it
locals {
  instances = flatten(local.serverconfig)
}
resource "aws_instance" "web" {
  for_each = {for server in local.instances: server.instance_name =>  server}
  ami           = each.value.ami
  instance_type = each.value.instance_type
  vpc_security_group_ids = each.value.security_groups
     # vpc_security_group_ids = [aws_security_group.awssg_jkn.id]
   key_name = "sparkkey_jkn"

 
  user_data = <<EOF
#!/bin/bash
echo "Installing JDK"
sudo yum install java-11-amazon-corretto -y
echo "Copying the SSH Key to the remote server"
echo "Changing the hostname to ${each.value.instance_name}"
hostname ${each.value.instance_name}
echo "${each.value.instance_name}" > /etc/hostname
sudo adduser ansible
sudo mkdir /home/ansible/.ssh
sudo chown ansible:ansible /home/ansible/.ssh
sudo chmod 700 /home/ansible/.ssh/
#echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFRt3+Dl3qQwJGP3bj0P/OHXHy2bUk2rDMokJQjfcsVr9YdcSl+CVQ9/IRNy7bSMRqcUqgyhvjZ4k01Oh7Wxdn5/O95l/f+EpDCJp/VG1OgKXnyCmYP7nOAKcaOmnBH/D1L7f6RIpcl4Jl1L3OxBVKNRt6x/jNPZjF8TY+/aRj2sIpEAlSlVwaNEGbT9QVlo2Tf6kEwm4DvZ2ggOMPUelwsBaDHDIzyanZYDU7rw04oP+XJlJA01ldMxMi74QOWokBz7jPb35m/1TSdsd3dBI+Zb5vAQJFFzQ67tdh85AT6oZCE4CoY+Y9scMUUU/dPIUZJIvzidepSKISyWgMDOq/ ansible@ip-172-31-68-44.ec2.internal" >> /home/ansible/.ssh/authorized_keys
echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3PI7GCww+optY4EoDlU/mVDNaUk+zd+i2OsLqNvI03NyM6nr4OCwKARGzBjegAGKtclG2om+FIH6vB2bRIv+k4jMYyxIz0tCuyCL3dnoEKzk87Nyd6nZGSZWG3SELShgG3k7qk+HM4mkj8lrgboyPyceWN6SsiXgDFYtvI8xZlglaR0EiziL/Mewj4CKqHE9e7TzQzaDYFdgUTdTz8LXyQBMlK6jigMen33kUa1cWNUMmssEaMcTa82J/hojO85l0XZxNHmZ5rXFfeTuRzT0HIYMyCFbWVLJKNNwFCOH8EcLlMkUnx+Ub2349EhIbzd2AElnk/pfN9CT7evMsINt9foxg6jUySYL9qjSdk/Ixh7cyMIWhKop+kATlyb+6K2Q768d2iXXxAcI2Z4UJYO/UKPqwPwaI6b2SApBoIcBsAksLJwMGtcwqbLIN1LlDcZ7pJN+9FifbpcVfx5ti+mlApNPnYrD2qwtLpI/fL0ElN0OxHIvwUf6N/D3E7gw/cec= ansible@ip-172-31-18-254.eu-north-1.compute.internal" >> /home/ansible/.ssh/authorized_keys
sudo chown ansible:ansible /home/ansible/.ssh/authorized_keys
sudo chmod 600 /home/ansible/.ssh/authorized_keys
sudo sed -i '63 s/^/#&/' /etc/ssh/sshd_config
sudo echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sudo echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
sudo su -
sudo echo "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sudo echo -e "12345678" | sudo passwd --stdin ansible
sudo service sshd restart
EOF
 ## subnet_id = each.value.subnet_id
  tags = {
    Name = "${each.value.instance_name}"
    cluster = "spk"
    Env = "${each.value.tag_name}"
  }
}

##############################

#Default VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }

}

output "instances" {
  value       = "${aws_instance.web}"
  description = "All Machine details"
}

#############################

#Key
resource "aws_key_pair" "awskey" {
  key_name   = "sparkkey_jkn"
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC838Zt/LMy2cJP505/k9eCc1i1Dqsn/CRgdMkiuJ3BQFeG/B1jmmQLYBbP1R6SWMALzlVTTeJJJBXRwHgKFYPQsBqxG4ilOVKozCtLq2azlooqbJRIOTGYqFffeqqj6jk1QDX0aEXgtgj1MnlU0DIbc326F54ED/k3tQ/P4Qte4wD/j2y7IgrZAYPMB0wlG70FJBTlFpLz/TTEtaQleO5mNMnMHDYCKH6gnb51pN7NFOE5aWv+wNMJaVbvVaCDTvtlCZYk3ylu9zgKGYM3A1NOG65avRoRjQxCBk803Fiy1vO4hYJT4XACwcUWcLbgmfX0ET2vJ8cHdYZSIBNDpTHX arshad.shaik@IN-IT6644"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLW4Cu2aI03AZHUmxAI4y3Mf83AabYPDkpHXa0GcbcgBQuq9uwRBV+NNCZcrdkbwFvPeShVJKiXOSkx2KKw9i6JDtLWz2NHWJUUHkT9zxUr7nz7C2ouE4LShfCHiYUxx2V6SAbDD2CRhMpKz6U8DtPHNQ1+HcMzI7i0ciGYfAkRXkN1oZyI9WcqkSZzkaaRTTgwp8dy592nc/9tsJFs0QlQXjcNFZdAZ1JQfB1Pbxni5Fl5Mz3Tu+xZY6TjT7L1jMG3U5Vl0K2rXvtkQUxtp2NHYxQQLPwzfD4y9nPaGtu1oC+AsorKaV76uEYxKC+poXIv/tmisPXqr7I7LEHsZ0L ec2-user@ip-172-31-18-254.eu-north-1.compute.internal"
}

#############################

# Security Group
resource "aws_security_group" "awssg_jkn" {
  name        = "awssg_jkn"
  description = "Allow TLS inbound traffic"
  #vpc_id      = aws_vpc.myvpc.id
  vpc_id = aws_default_vpc.default.id

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
 egress = [
    {
      description      = "TLS from VPC"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]

     prefix_list_ids  = []
      security_groups  = []
      self = false
    }
  ]

  tags = {
    Name = "allow_tls"
  }
}
