# Performance tests scenarios for Openshift.io Auth Services

## Test setup
 * **100** concurrent processes (simulated users)
 * **10** user accounts
 * accessing the tested server [auth.prod-preview](https://auth.prod-preview.openshift.io) from **10** individual client nodes,
 * each simulated user waits randomly between 1 to 10 seconds before sending the next request
 * test runs for 5 minutes twice an hour
   
## Test scenarios
The scenarios are described [here](https://github.com/fabric8-services/fabric8-auth/issues/209).

