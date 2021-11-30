# Introduction 

This project provides a quick way to create a GKE cluster and install the confluent operator.

Install Terraform     

```bash
brew install terraform
```

Login to Google

```bash
gcloud auth application-default login
```

Build the cluster

```bash
terraform apply
```

Configure kubectl to the new cluster.

```bash
./login-to-k8s.sh
```