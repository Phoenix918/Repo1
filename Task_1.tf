provider "aws" {
  region                  = "ap-south-1"
  profile                 = "pf1"
}


resource "aws_s3_bucket" "sb4" {
  bucket = "s4bucket918"
  acl    = "private"

  tags = {
    Name        = "Terra-bucket"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_public_access_block" "sbb" {

   depends_on = [
    aws_s3_bucket.sb4,
  ]
  
  bucket = "s4bucket918"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}


resource "aws_security_group" "sc5" {
  name        = "sc5"
  description = "created using terraform"
  vpc_id      = "vpc-7a899412"

  ingress {
    description = "ssh inbound rule using terraform"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }

  ingress {
    description = "http inbound rule using terraform"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }
  
  ingress {
    description = "https inbound rule using terraform"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }

  ingress {
    description = "custom tcp inbound rule using terraform"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks=["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sc5"
  }
}



resource "aws_key_pair" "tk3" {
  key_name   = "terrakey3"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA4kgdmLuEEDpcg6WP4xtHyg2qFUpqu8zApivKQHKhwL53hZw63n2jY6twstQOXn8VlEaSyBt5/oTHQbiD5NwIYWNFyoJOAia5tTPUIaHbhuicUsWAPgi2q3jvXV8bCWoWFBmewQB4yZ9HsRLCk88xEBLM0hSsbrgZeEmuMwaDMkwnwgizKpGBzvOlxH79FTpH5jJTt9L54jcYiglL/H8nPzGdYdBqskdzEVmcpE59kJ3gnkP0l/1I2watUbSBX/osGkJBcj3lCaUV8WCbbrz/qyR3Gk+9iyJLlPX+RgsrXq4lrHN2uCpQKuJ0vR/sJlVsTYXjzKI0iUq+zdkVtcJXhQ== rsa-key-20200611"
}



resource "aws_ebs_volume" "a" {
  availability_zone = aws_instance.i1.availability_zone
  size              = 1

  tags = {
    Name = "pd3"
  }
}



resource "aws_instance"  "i1" {

   depends_on = [
    aws_key_pair.tk3,
	aws_security_group.sc5,
  ]
  
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name	= "terrakey3"
  security_groups =  [ "sc5" ] 
  availability_zone = "ap-south-1a"

  tags = {
    Name = "terraos_1"
  }
}

resource "aws_volume_attachment" "ebs_att" {

   depends_on = [
    aws_ebs_volume.a,
  ]
  
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.a.id
  instance_id = aws_instance.i1.id
  force_detach = true
}


locals {
  s3_origin_id = aws_s3_bucket.sb4.bucket
}

resource "aws_cloudfront_distribution" "sbc" {
	
	 depends_on = [
   aws_s3_bucket_object.sbo,
  ]
  
  origin {
    domain_name = "${aws_s3_bucket.sb4.bucket}.s3.amazonaws.com"
    origin_id   = aws_s3_bucket.sb4.bucket

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E3NRGG0HS1Z25F"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = ""
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.sb4.bucket

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "TerraCloud"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_s3_bucket_policy" "sbp" {

  depends_on = [
   aws_s3_bucket_public_access_block.sbb,
  ]
  
  bucket = "s4bucket918"
  policy = <<EOF
{
  "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E3NRGG0HS1Z25F"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.sb4.bucket}/*"
        }
    ]
}
EOF
}



resource "aws_s3_bucket_object" "sbo" {

  depends_on = [
   aws_s3_bucket_policy.sbp,
  ]
  
  bucket = "s4bucket918"
  key    = "s3upload2.jpg"
  source = "/Users/KIIT/Downloads/s3upload2.jpg"
  content_type = "image/jpeg"
  content_disposition = "inline"
}

resource "null_resource" "nullresource"  {

 depends_on = [
   aws_cloudfront_distribution.sbc,
  ]

    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/KIIT/Downloads/terrakey3.pem")
    host     = aws_instance.i1.public_ip
  }

provisioner "remote-exec" {

    inline = [
      "sudo yum install httpd  php git -y",
	  "sudo systemctl start httpd",
	  "sudo systemctl enable httpd",
	  "sudo mkfs.ext4 /dev/xvdf ",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html",
      "sudo git clone https://github.com/Phoenix918/Repo1.git /var/www/html",
	  "sudo sed -i 's/old_domain/${aws_cloudfront_distribution.sbc.domain_name}/g' /var/www/html/s2.html" 
    ]
  }
}



resource "null_resource" "ncl"  {


depends_on = [
    null_resource.nullresource,
  ]

	provisioner "local-exec" {
	    command = "chrome  http://${aws_instance.i1.public_ip}/s2.html"
  	}
}
