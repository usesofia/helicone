variable "project_id" {
  type    = string
  default = "helicone-prod"
}

variable "region" {
  type    = string
  default = "southamerica-east1" # Região que corresponde a America/Sao_Paulo (São Paulo)
}

variable "sofia_team_ips" {
  description = "IPs of the Sofia team"
  type        = list(string)
  default = [
    "189.29.145.253", // marco@usesofia (Casa Santo André)
  ]
}