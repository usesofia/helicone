variable "region" {
  type = string
}

variable "sofia_team_ips" {
  description = "IPs of the Sofia team"
  type        = list(string)
}
