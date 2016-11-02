#--------------------------------
# Configure the AWS provider
#--------------------------------

provider "aws" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.access_secret}"
}
#--------------------------------
# Create VPC 
#--------------------------------

resource "aws_vpc" "vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-cloud-customers"
  }
}

#--------------------------------
# Create VPC public subnet
#--------------------------------
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "172.31.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}a"
  tags = {
  	Name =  "${var.region}.subnet-a"
  }
}

#--------------------------------
# Create VPC private subnets
#--------------------------------
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "172.31.2.0/24"
  availability_zone = "${var.region}a"
  tags = {
  	Name =  "${var.region}-subnet-a"
  }
}


#--------------------------------
# Create Internet Gateway 
#--------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
        Name = "InternetGateway"
    }
}

#--------------------------------
# Create route to the internet 
#--------------------------------
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

#--------------------------------
# Create Elastic IP (EIP)
#--------------------------------
resource "aws_eip" "eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.gw"]
}

#--------------------------------
# Create NAT Gateway
#--------------------------------
resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.eip.id}"
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    depends_on = ["aws_internet_gateway.gw"]
}

#--------------------------------
# Create private route table and the route to the internet 
#--------------------------------
resource "aws_route_table" "private_route_table" {
    vpc_id = "${aws_vpc.vpc.id}"
 
    tags {
        Name = "Private route table"
    }
}
resource "aws_route" "private_route" {
	route_table_id  = "${aws_route_table.private_route_table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

#--------------------------------
# Create Route Table Associations 
#--------------------------------
# Associate subnet public_subnet to public route table
resource "aws_route_table_association" "public_subnet_association" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}
 
# Associate subnet private_subnet to private route table
resource "aws_route_table_association" "private_subnet_association" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}
