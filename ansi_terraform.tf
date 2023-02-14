provider "aws" {
  region = "ap-south-1"
  profile = "terraform"
	
}

# Creating Security Group

resource "aws_security_group" "ansi-terra-sg" {
  name = "my-ansi-terra-sg"
  description = "Allow HTTP and SSH traffic via Terraform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#aws instance creation
resource "aws_instance" "os1" {
  ami           = "ami-010aff33ed5991201"
  instance_type = "t2.micro"
  vpc_security_group_ids =  [ aws_security_group.ansi-terra-sg.id ]
   key_name = "ansi-terra"
  tags = {
    Name = "TerraformOS"
  }
}


#IP of aws instance retrieved
output "op1"{
value = aws_instance.os1.public_ip
}

resource "local_file" "hosts" {
    content  = <<EOF
    [instance] 
    ${aws_instance.os1.public_ip} ansible_user=ec2-user  ansible_ssh_private_key_file=/home/ansible/ansible-mail/aws_key.pem
      EOF

    filename = "hosts"
}

//for instance ansible playbook
resource "null_resource" "instance_play" {
  triggers= {
      mytrigger=timestamp()
}
depends_on = [aws_instance.os1] 
connection {
	type     = "ssh"
	user     = "ansible"
	password = "${var.password}"
    	host= "${var.host}" 
  
}

 provisioner "remote-exec" {
    on_failure = continue
    inline = [
	"mkdir ansible-mail"
]
}
   provisioner "remote-exec" {
    inline = [
      "echo \"${file("C:\\Users\\priya\\Downloads\\ansi-terra.pem")}\" > /home/ansible/ansible-mail/aws_key.pem",
    ]
   }
  provisioner "file" {
    source      = "httpd.yml"
    destination = "/home/ansible/ansible-mail/httpd.yml"
  }
  provisioner "file" {
    source      = "ansible_variable.yml"
    destination = "/home/ansible/ansible-mail/ansible_variable.yml"
  }

  provisioner "file" {
    source      = "index.html"
    destination = "/home/ansible/ansible-mail/index.html"
  }

  provisioner "file" {
    source      = "httpd_config.conf"
    destination = "/home/ansible/ansible-mail/httpd_config.conf"
  }
   provisioner "file" {
    source      = "hosts"
    destination = "/home/ansible/ansible-mail/hosts"
  }
  provisioner "file" {
    source      = "ansible.cfg"
    destination = "/home/ansible/ansible-mail/ansible.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/ansible/ansible-mail",
      "chmod 600 aws_key.pem",
      "ansible-playbook httpd.yml"
    ]
  }
}
#connecting to the Ansible control node using SSH connection
resource "null_resource" "mail-remote" {
  triggers= {
      mytrigger=timestamp()
}
depends_on = [null_resource.instance_play] 
connection {
	type     = "ssh"
	user     = "ansible"
	password = "${var.password}"
    	host= "${var.host}" 
  
}

  provisioner "file" {
    source      = "mail.yml"
    destination = "/home/ansible/ansible-mail/mail.yml"
  }
 
  provisioner "file" {
    source      = "mysecret1.yml"
    destination = "/home/ansible/ansible-mail/mysecret1.yml"
  }
  provisioner "file" {
    source      = "vault.sh"
    destination = "/home/ansible/ansible-mail/vault.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "cd /home/ansible/ansible-mail",
      "export ANSIBLE_VAULT_PASSWORD=${var.vault}",
      "chmod +x vault.sh",
      "ansible-vault encrypt --vault-password-file ./vault.sh   mysecret1.yml",
      "cat mysecret1.yml",
      "ansible-playbook --vault-password-file ./vault.sh mail.yml"
    ]
  }

}



