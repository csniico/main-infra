provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}
