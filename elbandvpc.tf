provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Main-VPC"
  }
}


resource "aws_subnet" "public" {
  count             = length(var.subnet_cidrs_public)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs_public[count.index]
  availability_zone = element(var.subnet_azs, count.index)
  tags = {
    Name = "BU-UAT-PUB-SUBNET ${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count      = length(var.subnet_cidrs_private)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidrs_private[count.index]
  tags = {
    Name = "Private-Subnet ${count.index + 1}"
  }

}

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gw"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.subnet_cidrs_public)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.subnet_cidrs_private)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "allow-ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow-ssh"
  }
}


resource "aws_nat_gateway" "nat-gw" {
  count         = 1
  allocation_id = "eipalloc-028e6f1ad5977c452"
  subnet_id     = element(aws_subnet.private.*.id, count.index)
  tags = {
    Name = " NAT "
  }
}

resource "aws_ecs_cluster" "foo" {
  name = "white-hart"
}

resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${aws_vpc.main.id}"
     }

resource "aws_security_group" "my-alb-sg" {
  name   = "my-alb-sg"
  vpc_id = "${aws_vpc.main.id}"
}
resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.my-alb-sg.id}",]
  subnets            = aws_subnet.private.*.id

}

resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  }
}
