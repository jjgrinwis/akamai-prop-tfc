# Akamai Property Module

This module manages Akamai property configurations.

## Usage

```hcl
module "akamai_property" {
  source = "../../modules/akamai-property"

  environment = "dev"
  hostnames   = ["dev.grinwis.com"]

  # Add other Akamai-specific variables
}
```

## Requirements

- Terraform >= 1.5
- Akamai provider >= 9.3.0

## Inputs

| Name        | Description                           | Type         | Default | Required |
| ----------- | ------------------------------------- | ------------ | ------- | :------: |
| environment | Environment name (dev, staging, prod) | string       | n/a     |   yes    |
| hostnames   | The hostnames for the property        | list(string) | n/a     |   yes    |

## Outputs

| Name        | Description              | Type         |
| ----------- | ------------------------ | ------------ |
| environment | The environment name     | string       |
| hostnames   | The configured hostnames | list(string) |
