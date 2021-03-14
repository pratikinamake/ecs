

variable "vpc_cidr" {
  default = "10.10.0.0/22"
}

variable "subnet_cidrs_public" {
  description = "Subnet CIDRs for public subnets (length must match configured availability_zones)"
  # this could be further simplified / computed using cidrsubnet() etc.
  # https://www.terraform.io/docs/configuration/interpolation.html#cidrsubnet-iprange-newbits-netnum-
  default = ["10.10.0.0/25", "10.10.1.0/25"]
  type    = list(string)
}


variable "subnet_azs" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "subnet_cidrs_private" {
  description = "Subnet CIDRs for public subnets (length must match configured availability_zones)"
  # this could be further simplified / computed using cidrsubnet() etc.
  # https://www.terraform.io/docs/configuration/interpolation.html#cidrsubnet-iprange-newbits-netnum-
  default = ["10.10.2.0/25", "10.10.2.128/25", "10.10.3.0/25", "10.10.3.128/25"]
  type    = list(string)
}

