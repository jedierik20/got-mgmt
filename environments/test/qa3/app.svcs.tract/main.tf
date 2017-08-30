variable "quantity" {
  description = "How many of this type of server (nodes) are we creating"
  #### default = 1
  ### Note, don't set default because it should be explicitly CHOSEN or passed in.
}

variable "aws_instance_type" {
  description = "m4.large, m4.xlarge, etc.... for these servers"
  #### no default, again, we really don't want to make a mistake here!
  ### as we get better, we can/should make this a lookup against "server_role"?
}

variable "aws_tag_map" {
  type = "map"
  description = "The tract environment tags that this cluster is associated with."
  ###default = { }
  ### Don't set default.  This is loaded from ../common/ec2_env_tags
}

variable "server_role" {
  description = "The role to be used in puppet.conf for this server."
  #### not really used for Kibana servers.
  ### don't set a default!
}

variable "cluster_name" {
  description = "The puppet cluster name to be used in puppet.conf for this server (used as cluster_name AND cluster_group)."
  #### not really used for Kibana servers.
  ### don't set a default!
}

variable "aws_secgroup_list" {
  type = "list"
  description = "You need to list here your security groups for this cluster"
}

variable "aws_subnet_list" {
  type = "list"
  description = "The list of subnets that will be used for this cluster.  1 Host in each, looping around."
}

variable "hostnamebase" {
  description = "the text of the hostname where will will APPEND the quantity index (1-9)."
  ##### can't set default, this is too unique.  Example:
  #### currently can't build more than 9 with proper names (appending single digit?)
  ### example:  hostnamebase = "na2-nonprod-logskibana0"
}

variable "domainname" {
  description = "the domain name (not FQDN!) of these hosts."
  ### we will assemble FQDN later, this is JUST domain!
  ### example:  domainname = "private.gotransverse.com"
}

variable "aws_dnszone2update" {
  description = "DONT FORGET TRAILING DOT!  the Route53 hosted zone to update.  Must exist IN the region and match the domain."
  ### This could (and should) be done via a mapping file!
  ### example:   "private.gotransverse.com."
}

variable "aws_dnszoneprivate" {
  description = "Whether we are updating a private zone or a public zone."
  ### 
  ### 
}

variable "aws_rootvolsize" {
  description = "If making hosts, the size of the main/root volume."
  default = 25
  ### Gigbytes is assumed.
}

variable "aws_deleterootvolonterm" {
  description = "If making hosts, true if we want to delete root volume on termination."
  default = false
  ### NOT deleting is safer, but will cause an orphaned volume crisis eventually.
}

variable "aws_rootvoltype" {
  description = "If making hosts, the type of root volume."
  default = "gp2"
}

variable "aws_datavolsize" {
  description = "If making hosts, the size of the main/root volume."
  ### Gigbytes is assumed.
}

variable "aws_deletedatavolonterm" {
  description = "If making hosts, true if we want to delete root volume on termination."
  ### NOT deleting is safer, but will cause an orphaned volume crisis eventually.
}

variable "aws_datavoltype" {
  description = "If making hosts, the type of root volume."
}


variable "clusterdnsentry" {
  description = "The hostname (don't add the DOMAIN!) for making a cluster or service entry in DNS.  It's an A record, of all server IP's created here."
  ### This could (and should) be done via a mapping file!
  ### example:   "na2-nonprod-logselastic"
}

provider "aws" {
  region = "${lookup(var.aws_gotdc_region_map, var.aws_gotdc)}"
}

data "aws_ami" "baseline" {
  most_recent = true
  filter {
    name   = "image-id"
    values = ["${lookup(var.aws_gotami_map, var.aws_gotdc)}"]
  }
}

data "template_file" "user_data" {
  template = "${file("logselastic-cloud-init.yaml.tpl")}"
  count = "${var.quantity}"
  
  vars {
    # consul_address = "${aws_instance.consul.private_ip}"
    hostname = "${var.hostnamebase}${count.index + 1}"
    domain =  "${var.domainname}"
    location = "${lookup(var.puppet_location_map, var.aws_gotdc)}"
    puppet_server = "${lookup(var.puppet_server_map, var.aws_gotdc)}"
    puppet_environment = "${lookup(var.puppet_location_map, var.aws_gotdc)}"
    puppet_server_role = "${var.server_role}"
    puppet_cluster_name = "${var.cluster_name}"
    }
}

resource "aws_instance" "ec2_server" {
  count = "${var.quantity}"
  ami           = "${data.aws_ami.baseline.id}"
  instance_type = "${var.aws_instance_type}"
  key_name = "${lookup(var.key_name_map, var.aws_gotdc)}"
  ###
  #    AZ is not used for hosts.  Instead we use subnet id!
  #####availability_zone = "${var.aws_az_list[count.index]}"
  ##
  #
  security_groups = "${var.aws_secgroup_list}"
  subnet_id = "${element(var.aws_subnet_list,count.index)}"
  user_data = "${element(data.template_file.user_data.*.rendered,count.index)}" 
  root_block_device {
    delete_on_termination = "${var.aws_deleterootvolonterm}"
    volume_size = "${var.aws_rootvolsize}"
    volume_type = "${var.aws_rootvoltype}"
  }

  volume_tags {
    Name = "${var.hostnamebase}${count.index + 1}.${var.domainname}${var.aws_tag_map["rootvolname"]}"
    Environment = "${var.aws_tag_map["env"]}"
    EnvClass = "${var.aws_tag_map["envclass"]}"
    Customer = "${var.aws_tag_map["customer"]}"
    Billto = "${var.aws_tag_map["billto"]}"
    Owner = "${var.aws_tag_map["owner"]}"
    Maintainer = "${var.aws_tag_map["maintainer"]}"
    Budget = "${var.aws_tag_map["budget"]}"
  }

  tags {
    Name = "${var.hostnamebase}${count.index + 1}.${var.domainname}"
    Environment = "${var.aws_tag_map["env"]}"
    EnvClass = "${var.aws_tag_map["envclass"]}"
    Customer = "${var.aws_tag_map["customer"]}"
    Billto = "${var.aws_tag_map["billto"]}"
    Owner = "${var.aws_tag_map["owner"]}"
    Maintainer = "${var.aws_tag_map["maintainer"]}"
    Budget = "${var.aws_tag_map["budget"]}"
  }
}

resource "aws_ebs_volume" "datavol" {
  count = "${var.quantity}"
  ###
  availability_zone ="${element(aws_instance.ec2_server.*.availability_zone,count.index)}"

  size = "${var.aws_datavolsize}"
  type = "${var.aws_datavoltype}"

  tags {
    Name = "${var.hostnamebase}${count.index + 1}.${var.domainname}${var.aws_tag_map["datavolname"]}"
    Environment = "${var.aws_tag_map["env"]}"
    EnvClass = "${var.aws_tag_map["envclass"]}"
    Customer = "${var.aws_tag_map["customer"]}"
    Billto = "${var.aws_tag_map["billto"]}"
    Owner = "${var.aws_tag_map["owner"]}"
    Maintainer = "${var.aws_tag_map["maintainer"]}"
    Budget = "${var.aws_tag_map["budget"]}"
    }
}

resource "aws_volume_attachment" "datavol-attach" {
  count = "${var.quantity}"
  device_name = "/dev/sdb"
  volume_id   = "${element(aws_ebs_volume.datavol.*.id,count.index)}"
  instance_id = "${element(aws_instance.ec2_server.*.id,count.index)}"
}

data "aws_route53_zone" "selected" {
  name         = "${var.aws_dnszone2update}"
  private_zone = "${var.aws_dnszoneprivate}"
}

resource "aws_route53_record" "ec2_server" {
  count = "${var.quantity}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${element(aws_instance.ec2_server.*.tags.Name,count.index)}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.ec2_server.*.private_ip,count.index)}"]
}

resource "aws_route53_record" "servicecluster" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.clusterdnsentry}.${var.domainname}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ec2_server.*.private_ip}"]
}
