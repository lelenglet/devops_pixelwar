# https://www.youtube.com/watch?v=BZ2TLtf3yFg

data "http" "ip" {
  url = "https://example.com"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "opentofu-bucket"
}