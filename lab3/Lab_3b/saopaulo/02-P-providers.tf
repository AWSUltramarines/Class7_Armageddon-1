# São Paulo Liberdade - Default provider
provider "aws" {
  region = "sa-east-1"
}

# Add this alongside your existing sa-east-1 provider
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}