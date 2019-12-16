variable "domains" {
  description = "Map of domain names and their Route 53 zones"
  type        = map(string)
}
