# Terraform LocalStack AWS Architecture

This project uses Terraform to provision an AWS architecture entirely within [LocalStack](https://localstack.cloud/). It is based on the architecture diagram provided, allowing for local development, testing, and experimentation without incurring any AWS costs.

The infrastructure built matches this diagram:


## Architecture Overview

This Terraform configuration builds the following components to replicate the diagram:

* **Networking (VPC):**
    * A new VPC (`10.0.0.0/16`).
    * **Two Public Subnets** across two Availability Zones (for high availability).
    * **Two Private Subnets** across two Availability Zones (for secure application and database layers).
    * An **Internet Gateway** (IGW) to allow internet access to the public subnets.
    * A **NAT Gateway** (the "shield" icon) in a public subnet to allow outbound internet access for resources in the private subnets.
    * Public and Private **Route Tables** to manage traffic flow.

* **Application & Compute (EC2):**
    * An **Application Load Balancer (ALB)** in the public subnets to distribute incoming traffic.
    * An **Auto Scaling Group** launching **EC2 Instances** within the private subnets.
    * A **Launch Template** that bootstraps EC2 instances with a simple web server (httpd) and mounts the EFS filesystem.
    * An **EC2 Key Pair** (the "key" icon) for potential SSH access.

* **Security:**
    * **AWS WAFv2** (the "firewall" icon) associated with the Application Load Balancer.
    * **Security Groups** to control traffic between the ALB, EC2 instances, EFS, and RDS.

* **Storage & Database:**
    * An **Amazon S3 Bucket**.
    * An **Elastic File System (EFS)** (the "elastic" pink icon) accessible from both private subnets for shared storage.
    * An **RDS (PostgreSQL) Database** (the "R" icon) deployed in the private subnets.

* **DNS (Route 53):**
    * A public **Route 53 Hosted Zone** (`example.com`).
    * An **Alias Record** (`www.example.com`) pointing to the Application Load Balancer.

## Prerequisites

1.  **Terraform:** Must be installed on your system.
    * [Install Terraform](https://developer.hashicorp.com/terraform/install)
2.  **LocalStack:** Must be installed and running. The simplest way is via Docker.
    * [Install LocalStack](https://docs.localstack.cloud/getting-started/installation/)
    * Ensure the LocalStack container is running:
        ```bash
        localstack start -d
        # Or if using docker-compose
        docker-compose up -d
        ```

## 🚀 How to Run

1.  **Clone the Repository (or Save the Files):**
    Ensure you have all the `.tf` files in a single directory:
    * `provider.tf`
    * `main.tf`
    * `variables.tf`
    * `outputs.tf`

2.  **Update SSH Key Variable:**
    Open the `variables.tf` file. You **must** update the `default` value of the `ssh_public_key` variable to your own public key.

3.  **Initialize Terraform:**
    Open a terminal in the project directory and run:
    ```bash
    terraform init
    ```
    This will download the necessary AWS provider plugin.

4.  **Apply the Configuration:**
    Run the apply command to build the infrastructure inside LocalStack:
    ```bash
    terraform apply
    ```
    Terraform will show you a plan. Review the resources and type `yes` to approve and begin provisioning.

5.  **Test the Application:**
    Once the apply is complete, Terraform will display the outputs.
    * Find the `load_balancer_dns` output.
    * Test it using `curl` or your browser:
        ```bash
        curl http://<load_balancer_dns_from_output>
        ```
    * You should see a "Hello from..." message, which may change as you refresh and hit different EC2 instances.

6.  **Verify in LocalStack:**
    You can also visit the LocalStack Web UI to see all the created resources (VPC, EC2, RDS, etc.) visually.

## 🧹 How to Clean Up

When you are finished, you can destroy all the resources created in LocalStack by running:
```bash
terraform destroy