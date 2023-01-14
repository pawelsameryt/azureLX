variable "location" {
    type = string
    default = "northeurope"
}
variable "rgName" {
    type    = string
    default = "RG-tf-mgm"
}
variable "netName" {
    type    = string
    default = "net-tf-mgm"
}
variable "subnetName" {
    type    = string
    default = "subnet-tf-mgm"
}
variable "vmName" {
    type    = string
    default = "vmMGM"
}

variable "user" {
    type = string
    default = "pafcio"
}

variable "pass" {
    type = string
    default = "P@fcio123456"
}