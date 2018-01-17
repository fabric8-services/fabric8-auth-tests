# Openshift.io Auth Services Performance Evaluation
These tests are intended to measure performance of the REST endpoints of the OSIO Auth Services
as well as the user experience such as login from the OSIO UI.

## Environment
The tested server is the OSIO [Auth Services deployed in prod-preview](https://auth.prod-preview.openshift.io/api/status).
The clients to the tested server are deployed on the client nodes 
of the [OsioPerf Lab](https://github.com/fabric8-services/fabric8-auth-tests/blob/master/performance/README.md).

## Test setup
The test in the environment is executed with 10 tested OSIO user accounts that has a GitHub account linked.
The user accounts are evenly spread between 10 individual client nodes of the OsioPerf Lab
from whose the requests are sent via 100 simultaneous clients (=simulated users). Each simulated user waits randomly between 1 to 10 seconds
before sending another request.

The whole performance test suite is executed regularly each 30 minutes
while a single run takes a login phase + 5 minutes of load phase (see below). The summary results of each run
are uploaded to the [Zabbix](https://zabbix.devshift.net:9443/zabbix/charts.php?fullscreen=1&graphid=8575) monitoring system
to track the results' history. 

## Scenarios
The performance test suite is divided into two phases of testing:
 * *Prepare* - where each test user is logged in via UI once, while times to certain checkpoints are measured.
 * *Load* - where requests are sent to the tested endpoints repeatedly, while the response time is measured. 

### Prepare phase
Executed once per user to get user’s tokens, ID and name before the load test begins.
This is necessary to obtain access tokens for the requests to the secured endpoints.

#### *Open login page* (`open-login-page-time`)
From `GET /api/login?redirect=http://localhost:8090/link.html` wait for the `LOG IN` button to be clickable
which indicates that the page is loaded.

#### *Login the user* (`login-time`)
From clicking on the `LOG IN` button wait for the redirect to the `http://localhost:8090/link.html?token_json=<JSON>`.

From the redirect URL extract the `<JSON>` part and from in the `auth_token` and `refresh_token`.

Run `auth-api-user` scenario once to get the user’s info and extract the `username` and `user ID`.

### Load phase
#### *Get user info by token* (`auth-api-user`)
```
GET /api/user
Authorization: Bearer <auth_token>
```

#### *Get user by ID* (`api-user-by-id`)
```
GET /api/users/<user ID>
```

#### *Find user by name* (`api-user-by-name`)
```
GET /api/users?filter[username]=<username>
```

#### *Refresh user's auth token* (`auth-api-token-refresh`)
```
POST /api/token/refresh
Authorization: Bearer <auth_token>
Content-Type: application/json

{"refresh_token":"<refresh_token>"}
```

#### *Get access tokens for linked GitHub account* (`auth-api-user-github-token`)
```
GET /api/token?for=https://github.com
Authorization: Bearer <auth_token>
```

## How to run the tests locally
By default the load test executed by Locust tool runs in a distributed mode, i.e. uses remote access
to the Master and Slave nodes via SSH to start Locust process on those nodes to load the tested system
from a different places.

However, it is possible to switch the test to the local execution. To do that simply set the environment
variable `RUN_LOCALLY=true`. The easiest way is to uncomment the respective line in `_setenv.sh` file.

To run the test, configure the test in `_setenv.sh` file and run the `run.sh` script.
