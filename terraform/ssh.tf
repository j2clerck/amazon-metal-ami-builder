# © 2018 Amazon Web Services, Inc. or its affiliates. All Rights Reserved. 
# This AWS Content is provided subject to the terms of the AWS Customer Agreement 
# available at http://aws.amazon.com/agreement or other written agreement between 
# Customer and Amazon Web Services, Inc.
resource "aws_instance" "jenkins_master_ssh" {
  ami           = "${data.aws_ami.amzn-linux.id}"
  instance_type = "i3.metal"
  key_name      = "${aws_key_pair.generated_key.key_name}"
  subnet_id     = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"  ]
  iam_instance_profile = "ec2-ssm-role"

  tags {
    Name = "Ansible+SSH"
  },
  
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("${path.cwd}/key.pem")}"
  }
  provisioner "remote-exec" {
         script = "script/wait_for_instance.sh"
    },
  provisioner "local-exec" {
         command = "sleep 30; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key '${path.cwd}/key.pem' -i '${self.public_ip},' ubuntu_packer.yml"
    }
}

resource "tls_private_key" "tmp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  key_name_prefix   = "redeploy_temp_key"
  public_key = "${tls_private_key.tmp_key.public_key_openssh}"
}
resource "local_file" "ssh_key"{
  content = "${tls_private_key.tmp_key.private_key_pem}"
  filename = "${path.cwd}/key.pem"
  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/key.pem"
}
}
