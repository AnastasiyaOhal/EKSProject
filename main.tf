# resource "aws_iam_role" "demo" {
#   name = "eks-cluster-demo"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "eks.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.demo.name
# }

# resource "aws_eks_cluster" "demo" {
#   name     = "demo"
#   version  = "1.27"
#   role_arn = aws_iam_role.demo.arn

#   vpc_config {
#     subnet_ids = [
#       aws_subnet.private-us-east-1a.id,
#       aws_subnet.private-us-east-1b.id,
#       aws_subnet.public-us-east-1a.id,
#       aws_subnet.public-us-east-1b.id
#     ]
#   }

#   depends_on = [aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy]
# }

# resource "aws_iam_role" "nodes" {
#   name = "eks-node-group-nodes"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })
# }

# resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.nodes.name
# }

# resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.nodes.name
# }

# resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.nodes.name
# }

# resource "aws_eks_node_group" "private-nodes" {
#   cluster_name    = aws_eks_cluster.demo.name
#   node_group_name = "private-nodes"
#   node_role_arn   = aws_iam_role.nodes.arn

#   subnet_ids = [
#     aws_subnet.private-us-east-1a.id,
#     aws_subnet.private-us-east-1b.id
#   ]

#   capacity_type  = "SPOT"

#   instance_types = ["t3.small"]

#   scaling_config {
#     desired_size = 2
#     max_size     = 10
#     min_size     = 0
#   }

#   update_config {
#     max_unavailable = 3
#   }

#   labels = {
#     role = "general"
#   }

#    taint {
#      key    = "team"
#      value  = "devops"
#      effect = "NO_SCHEDULE"
#    }

#    launch_template {
#      name    = aws_launch_template.eks-with-disks.name
#      version = aws_launch_template.eks-with-disks.latest_version
#    }

#   depends_on = [
#     aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

#  resource "aws_launch_template" "eks-with-disks" {
#    name = "eks-with-disks"

#    key_name = "local"

#    block_device_mappings {
#      device_name = "/dev/xvdb"

#      ebs {
#        volume_size = 50
#        volume_type = "gp2"
#      }
#    }
#  }


# # This will allow granting IAM permissions based on the service account used by the pod
# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
# }

# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# module "irsa-ebs-csi" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "4.7.0"

#   create_role                   = true
#   role_name                     = "AmazonEKSTFEBSCSIRole-demo"
#   provider_url                  = aws_iam_openid_connect_provider.eks.oidc_provider
#   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# }
