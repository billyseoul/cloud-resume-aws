#!/usr/bin/env python3

##############################################################################
# PREREQUISITES: Deploy CloudFront first and get the domain name provided
# Directory: applications/resume-site/deployments/frontend && terragrunt apply
##############################################################################

import os
import sys
import requests

key = os.getenv("GODADDY_API_KEY")
secret = os.getenv("GODADDY_API_SECRET")
domain = os.getenv("GODADDY_DOMAIN")
cf = os.getenv("CLOUDFRONT_DOMAIN")

if not all([key, secret, domain, cf]):
    print("Set: GODADDY_API_KEY, GODADDY_API_SECRET, GODADDY_DOMAIN, CLOUDFRONT_DOMAIN")
    sys.exit(1)

headers = {"Authorization": f"sso-key {key}:{secret}"}
url = f"https://api.godaddy.com/v1/domains/{domain}/records/CNAME"

requests.put(f"{url}/www", headers=headers, json=[{"data": cf, "ttl": 600}])
print(f"www.{domain}")

try:
    requests.put(f"{url}/@", headers=headers, json=[{"data": cf, "ttl": 600}])
    print(f"{domain}")
except:
     print(f"Could not update record for {domain}. Go to the GoDaddy website and add the record manually.")
