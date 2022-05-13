variable "credentials" {
  type = object({
    access_key = "KHYJGTHNBVHXYZ"
    secret_key = "Kuxlkjhlkjhlkjh;a;sdkd;shwhZGs31o"
  })
}

variable "cluster_name" {
    type    = string
    default = "test-Cluster"
}

variable "node_role_arn" {
    type = string
    default = "arn:aws:iam::xxxxxxxxxxx:role/prod-nodeRole"
}

variable "cluster_iam_role_arn" {
    type = string
    default = "arn:aws:iam::xxxxxxxxxx:role/prod-eks-clusterRole"
  
}

variable "cluster_iam_role_name" {
    type = string
    default = "eks-ClusterRole"
}
