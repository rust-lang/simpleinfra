///////////////////////////////////
//   GitHub Pages IP addresses   //
///////////////////////////////////

data "http" "github_api_meta" {
  url = "https://api.github.com/meta"

  request_headers = {
    "Accept"     = "application/json"
    "User-Agent" = "https://github.com/rust-lang/simpleinfra (terraform)"
  }
}

locals {
  github_pages_ipv4 = [for ip in jsondecode(data.http.github_api_meta.body).pages : cidrhost(ip, 0)]
}
