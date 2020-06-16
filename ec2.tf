provider "aws"{
region = "ap-south-1"
profile = "sirshendudutta"
}

resource "tls_private_key" "example" {

	public_key = "${tls_private_key.example.public_key_openssh}"
}
resources "local_file" "mykey" {
content = "${tls_private_key.example.private_key_pem}"
filename = "C:\Users\SIRSHENDU DUTTA\Downloads/sirshendud1.pem"
file_permission=0400
}
resource "aws_security_group" "allow_tlsp" {
name  = "allow_tlsp"
description = "Allow TLS inbound traffic"

ingress {
from_port = 0
to_port = 0
protocol = -1
cidr_blocks = ["0.0.0.0/0"]
}
 egress {
	from_port = 0
	to_port	  = 0
	protocol  = "-1"
	cidr_blocks = ["0.0.0.0/0"
}

tags = {
   Name	= "allow_tlsp"
 }
}

resources "aws_instance" "LinuxOS" {
ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name="${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_tlsp.id}"]
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.example.private_key_pem
    host     = aws_instance.LinuxOS.public_ip
  }
 provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
  tags = {
    Name = "Myfirstos"
  }
}

resource "aws_ebs_volume" "persistent_storage" {
  availability_zone = aws_instance.LinuxOS.availability_zone
  size              = 1
  tags = {
    Name = "ebs_volume"
  }
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.persistent_storage.id
  instance_id = aws_instance.LinuxOS.id
 
}

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Avanish474/AWS-infrastructure-using-Terraform-without-manual-approach-.git /var/www/html/"
    ]
  }
}



