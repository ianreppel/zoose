"""Shared authentication defaults for /jupyter.sh and direct jupyter lab launches."""
import os

c.IdentityProvider.token = os.environ.get("ZOOSE_TOKEN", "")
c.PasswordIdentityProvider.hashed_password = ""
