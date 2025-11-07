variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0OmkuRlas3IiDSQaVtPEQPCOEkb7AH4SoCTOV7+Vc6c71Lgqa0kJNOZv1KuH2rPFSE+DgaUwKp58k3vNzjOmOVa7UHe12X4Ffspz3Q6Jlwv3tiRPd2cQZaOwkDX1n2sUw4BE8pqSOcuy0s+9jPwaIwk0RxQddv8xKH1Clzw5ozGbD99rV+2NnaAQxhX0gVtEFN3pJB+bUwrSUjye4xRqZCmaMWgnAE1apPTrYu3/q9P2v1rzh6yGY6WcBsookytE4NQmq4eclFjbraZmTAQSHUm3/63Ul6HRmZOhBuAX1IUKnLUGZ3qPx76J9n+5AB4dKNybN7+4UlMU3sP+RXNYApQG41WWomcyrdggdQwLcMJqEIerilY8Frd8YbTgmyQ8NtcJQghsmMpX7geCdtq9aGuhH1pZFKzTxDYkaCPsP2J8zMEzm/Y5hjV6CKUPxqe58MbF8NVe23xEKojardiUTtqW+FgFnFmbDC+80LWzsjLg10i/jSfytWSNUZIUcmQqtBH9kHRr9R/IerD+Wn871vsWrKoWRFMrWh4S/zNEq87GnFXH+yL160ep0dj6UYA6HL7exQcOlMw+dbXERGq2z4rA13bwIftOYZUiOmcPFfOM82NZvHK6/AsggTlqa8TqOSiPs9OCpkPYBF7EwKfLsTfwqdKmo0X9tWqlq0/QDGQ== tasneem-sherif@tasneem-sherif"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
}