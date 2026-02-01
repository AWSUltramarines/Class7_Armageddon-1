/*    # Add to 02-providers.tf temporarily
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}  */
  
# Tokyo Shinjuku 
provider "aws" {
  region = "ap-northeast-1"

  }

# ADD TO EXISTING 02-providers.tf
provider "aws" {
  alias  = "saopaulo"
  region = "sa-east-1"
}