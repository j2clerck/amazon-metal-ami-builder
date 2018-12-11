resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"

  tags {
    Name = "${var.vpc_name}"
  }
}

#SUBNET DECLARATION
resource "aws_subnet" "public1" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 2, 0)}"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.vpc_name} - public1"
  }
}

#GATEWAYS
resource "aws_internet_gateway" "internet" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.vpc_name}"
  }
}



#ROUTE TABLE DECLARATION
resource "aws_route_table" "public" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet.id}"
  }

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.vpc_name} - public"
  }
}

#ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public1" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${aws_subnet.public1.id}"
}


#DEFAULT NACL
resource "aws_network_acl" "public" {
  subnet_ids = ["${aws_subnet.public1.id}", "${aws_subnet.public2.id}"]
  vpc_id     = "${aws_vpc.main.id}"

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}
