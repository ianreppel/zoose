"""Shared authentication defaults for /jupyter.sh and direct jupyter lab launches."""
import os
import secrets

token = os.environ.get("ZOOSE_TOKEN")
if not token:
    token = secrets.token_urlsafe(32)
    print(
        "ZOOSE_TOKEN is empty: a random token guards this session.\n"
        f"JupyterLab: http://localhost:8888/lab?token={token}",
        flush=True,
    )
c.IdentityProvider.token = token
c.PasswordIdentityProvider.hashed_password = ""
