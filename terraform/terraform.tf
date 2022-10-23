terraform {
  backend "consul" {
    address = "192.168.1.152:8500"
    scheme  = "http"
    path    = "terraform"
  }
}

provider "consul" {
  address = "http://192.168.1.152:8500"
}

provider "nomad" {
  address = "http://192.168.1.152:4646"
  region  = "global"
}
