# Openshift.io Auth Services Performance
## Environment
Openstack cluster with 10 nodes
Auth.prod-preview over internet

## Test setup
100 users/10nodes/10accounts/5minutes/1-10s wait

## Scenarios
### Prepare test
Executed once per user to get user’s tokens, ID and name before the load test begins.
This is necessary to obtain access tokens for the requests to the secured endpoints.

#### Open login page (`open-login-page-time`)
From `GET /api/login?redirect=http://localhost:8090/link.html` wait for the `LOG IN` button to be clickable
which indicates that the page is loaded.

#### Login the user (`login-time`)
Click on the `LOG IN` button and wait for the redirect to the `http://localhost:8090/link.html?token_json=<JSON>`.

From the redirect URL extract the `<JSON>` part and from in the `auth_token` and `refresh_token`.

Run `auth-api-user` scenario once to get the user’s info as a JSON and extract the `username` and `user ID`.

### Load test
#### Get user info by token (`auth-api-user`)
```
GET /api/user
Authorization: Bearer <auth_token>
```

#### Get user by ID (`api-user-by-id`)
```
GET /api/users/<user ID>
```

#### Find user by name (`api-user-by-name`)
```
GET /api/users?filter[username]=<username>
```

#### Refresh auth token (`auth-api-token-refresh`)
```
POST /api/token/refresh
Authorization: Bearer <auth_token>
Content-Type: application/json

{"refresh_token":"<refresh_token>"}
```

#### Get tokens for linked GitHub account (`auth-api-user-github-token`)
```
GET /api/token?for=https://github.com
Authorization: Bearer <auth_token>
```
