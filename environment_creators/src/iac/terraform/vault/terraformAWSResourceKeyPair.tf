resource "aws_key_pair" "vault_key_pair" {
  key_name   = "vault_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

