variable "credentials" {
  type = object({
    access_key = "AKIA3EFCP7GHU2JPREBR"
    secret_key = "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"
  })
}

variable "cluster_name" {
    type    = string
    default = "test-Cluster"
}

variable "node_role_arn" {
    type = string
    default = "arn:aws:iam::764844964239:role/prod-nodeRole"
}

variable "cluster_iam_role_arn" {
    type = string
    default = "arn:aws:iam::764844964239:role/prod-eks-clusterRole"
  
}

variable "cluster_iam_role_name" {
    type = string
    default = "crain-eks-ClusterRole"
}