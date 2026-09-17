if ((req.method == "GET" || req.method == "HEAD") &&
    req.url.path ~ "^/api/v1/crates/([A-Za-z][A-Za-z0-9_-]{0,63})/([A-Za-z0-9.+-]+)/(download|readme)$") {
  declare local var.name STRING;
  declare local var.version STRING;
  declare local var.resource STRING;
  set var.name = re.group.1;
  set var.version = re.group.2;
  set var.resource = re.group.3;

  set var.version = regsuball(var.version, "[+]", {"%2B"});
  if (var.resource == "download") {
    error 600 "/crates/" var.name "/" var.name "-" var.version ".crate";
  } else {
    error 600 "/readmes/" var.name "/" var.name "-" var.version ".html";
  }
}
