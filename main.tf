terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74"
    }
  }
}

provider "aws"  {
         
    region = "us-east-1"
     
   
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
#echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvhXuMn9FwsrcK/DkgOlZdQFbY9e0+InX2sdHm8ZF7hGOQvg3CTMdBtMHlALnzqsYlS0aN0puzNF7fWAvUawdGjcSYxKEMlO1CaKPYxEgLTPDdiuYm3DNUutNMOLB0KHSJDk1Vb83UEpXm4vZjAWwHQTgoSsyXA57GcV4+IiTOy+iIIiiB7XzTDjt7ePVOW237HJAENlB/txh0qEl4Gn0eNGykg2E00jN8cOfIf/sKuY2kXBRgSjTjr6HArB4an6+aJpNJMWFFLyk47+NOIepaZhJNuXL39y0kGp/KzTlQw45g+ct92CSoCvySGqSUGN85ofPeYfzwB45yVJ9bMrZpY88TG4kLGAFeAg4DHVxUmJQhbjQOBRL8FDadOZuHmawlBUNeqFFtQ1EAad9Z2FWAZ80htaPysE9coA2VXC559VapIs9fsx2nPStKoB8bPP91rArS4Q9tt077+BgPE3d4IK2GRTYsC1TXzrF6hvGGk9zk+nWpZMqDtW5sQxdxl0k=" >> /home/ansible/.ssh/authorized_keys
#echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHoRVOQ6qFpSX0/UTdRRqO9GavOeJGkom0bIALN3OZdYOtkjBLdyDS09YVbrT4BL7FIX3EFARTl+hSRDgV5Gg10tnRs1o3FrXG7hx9xrwBxPuGdocRZQUryNPn6q59zcScKEOJjqQDhAXHUFONDRv/B9y/Dga1mK1qiu8Ysw/mNpLnD7VC0ROKureynhy3PeWw6BBkNCc9tx4dCo0LkibXC2wbh83WGHLYX1YpSRYN9BZLPpzOLuPwR087xh7rtxnDbE7NpMIH5bWee5vilVyVhVr9yhIAEyrz6FF0iWhUQGxqJP3BPVR5MugpjHuuHMqQpRo7fqLbc788KMeZzH0J ansible@ip-172-31-0-117.us-east-2.compute.internal" >> /home/ansible/.ssh/authorized_keys
echo "Changing the hostname to ${each.value.instance_name}"
hostname ${each.value.instance_name}
echo "${each.value.instance_name}" > /etc/hostname
sudo adduser ansible
sudo mkdir /home/ansible/.ssh
sudo chown ansible:ansible /home/ansible/.ssh
sudo chmod 700 /home/ansible/.ssh/
echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHoRVOQ6qFpSX0/UTdRRqO9GavOeJGkom0bIALN3OZdYOtkjBLdyDS09YVbrT4BL7FIX3EFARTl+hSRDgV5Gg10tnRs1o3FrXG7hx9xrwBxPuGdocRZQUryNPn6q59zcScKEOJjqQDhAXHUFONDRv/B9y/Dga1mK1qiu8Ysw/mNpLnD7VC0ROKureynhy3PeWw6BBkNCc9tx4dCo0LkibXC2wbh83WGHLYX1YpSRYN9BZLPpzOLuPwR087xh7rtxnDbE7NpMIH5bWee5vilVyVhVr9yhIAEyrz6FF0iWhUQGxqJP3BPVR5MugpjHuuHMqQpRo7fqLbc788KMeZzH0J ansible@ip-172-31-0-117.us-east-2.compute.internal" >> /home/ansible/.ssh/authorized_keys
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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC838Zt/LMy2cJP505/k9eCc1i1Dqsn/CRgdMkiuJ3BQFeG/B1jmmQLYBbP1R6SWMALzlVTTeJJJBXRwHgKFYPQsBqxG4ilOVKozCtLq2azlooqbJRIOTGYqFffeqqj6jk1QDX0aEXgtgj1MnlU0DIbc326F54ED/k3tQ/P4Qte4wD/j2y7IgrZAYPMB0wlG70FJBTlFpLz/TTEtaQleO5mNMnMHDYCKH6gnb51pN7NFOE5aWv+wNMJaVbvVaCDTvtlCZYk3ylu9zgKGYM3A1NOG65avRoRjQxCBk803Fiy1vO4hYJT4XACwcUWcLbgmfX0ET2vJ8cHdYZSIBNDpTHX arshad.shaik@IN-IT6644"
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
