variable "configuration" {
  description = "The total configuration, List of Objects/Dictionary"
  default = [{}]
}

variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22, 8080, 18080, 8081, 7077]
}