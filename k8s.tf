# cluster/cluster_auth data for the kubernetes and helm providers
data "aws_eks_cluster" "my_cluster" {
  name = "my_cluster"
}

data "aws_eks_cluster_auth" "my_cluster" {
  name = "my_cluster"
}

# kubernetes provider initialized without passing kubeconfig
provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.my_cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.my_cluster.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.my_cluster.token}"
  load_config_file       = false
  version                = "1.6.0"
}

# create a namespace
resource "kubernetes_namespace" "infra" {
  metadata {
    name = "infra"

    labels {
      name = "infra"
    }
  }
}

# create a test pod
resource "kubernetes_pod" "nginx" {
  metadata {
    name      = "nginx-spike"
    namespace = "${kubernetes_namespace.infra.id}"

    labels = {
      App = "nginx"
    }
  }

  spec {
    container {
      image = "nginx:1.7.8"
      name  = "spike"

      port {
        container_port = 80
      }
    }
  }
}

# create service account for tiller
resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

# create cluster-admin role binding for tiller
resource "kubernetes_cluster_role_binding" "tiller" {
  depends_on = ["kubernetes_service_account.tiller"]

  metadata {
    name = "tiller"
  }

  role_ref {
    name      = "cluster-admin"
    kind      = "ClusterRole"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    name      = "tiller"
    kind      = "ServiceAccount"
    namespace = "kube-system"
  }
}

# helm provider initialized without passing kubeconfig and also install tiller using the tiller service account
provider "helm" {
  version         = "0.10.2"
  install_tiller  = true
  service_account = "${kubernetes_service_account.tiller.metadata.0.name}"

  kubernetes {
    host                   = "${data.aws_eks_cluster.my_cluster.endpoint}"
    cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.my_cluster.certificate_authority.0.data)}"
    token                  = "${data.aws_eks_cluster_auth.my_cluster.token}"
    load_config_file       = false
  }
}

# create a test helm release pod
resource "helm_release" "kube-ops-view" {
  depends_on = ["kubernetes_service_account.tiller", "kubernetes_cluster_role_binding.tiller"]
  name       = "kube-ops-view"
  repository = "stable"
  chart      = "kube-ops-view"
  namespace  = "infra"
  version    = "1.1.0"
}
