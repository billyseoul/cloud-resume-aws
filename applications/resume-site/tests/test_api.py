import requests
import boto3

#############################################################################
# Some API Integration Tests for my Cloud Resume Challenge.
# Testing the visitor counter API endpoint functionality before deploying
#############################################################################
"""
Fetch the configuration value from AWS SSM Parameter Store
Args:
    parameter_name: SSM parameter path (Example: '/cloud-resume/region')
    region: AWS region (defaults to us-east-1 for bootstrapping)
Returns:
    String value of the SSM parameter
"""


#############################################################################
def get_ssm_value(parameter_name, region="us-east-1"):
    ssm = boto3.client("ssm", region_name=region)
    response = ssm.get_parameter(Name=parameter_name)
    return response["Parameter"]["Value"]


##############################################################################

"""
Dynamically fetch the API Gateway URL from SSM
Returns:
    Full API endpoint URL (Example: https://xxx.execute-api.us-east-1.amazonaws.com/blah/blah)
"""


##############################################################################
def get_api_url():
    # Get the region from SSM (using default region to bootstrap)
    region = get_ssm_value("/cloud-resume/region")
    # Get the API URL from the region variable
    return get_ssm_value("/cloud-resume/api_gateway_url", region=region)


##############################################################################

"""
Test 1: Verify API endpoint is reachable and returns HTTP 200 OK
Ensures the API Gateway and Lambda are properly deployed and responding
"""


##############################################################################
def test_api_return_200():
    response = requests.get(get_api_url())
    assert response.status_code == 200


##############################################################################
"""
Test 2: Verify response contains 'count' field as an integer
Verifies DynamoDB is returning valid counter data in correct format
"""
##############################################################################


def test_count_is_integer():
    response = requests.get(get_api_url())
    data = response.json()
    assert isinstance(data["count"], int)


##############################################################################
"""
Test 3: Verify visitor count increments by 1 on each request
Ensures Lambda is correctly updating DynamoDB counter logic
"""
##############################################################################


def test_count_increments():
    # First request - get current count
    response1 = requests.get(get_api_url())
    count1 = response1.json()["count"]

    # Second request - should increment by 1
    response2 = requests.get(get_api_url())
    count2 = response2.json()["count"]

    assert count2 == count1 + 1
