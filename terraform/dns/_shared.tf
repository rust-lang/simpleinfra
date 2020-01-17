// Variables used by other files in this directory.

locals {
  // List of IPv4 addresses we need to use when pointing to GitHub pages in an
  // A record. The list of IPs was fetched from:
  //
  //    https://help.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain
  //
  github_pages_ipv4 = [
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153",
  ]

  // MX records to use when a domain's mail is managed by Mailgun.
  mailgun_mx = ["10 mxa.mailgun.org", "10 mxb.mailgun.org"]

  // SPF record to use when a domain's mail is managed by Mailgun.
  mailgun_spf = "v=spf1 include:mailgun.org ~all"
}
