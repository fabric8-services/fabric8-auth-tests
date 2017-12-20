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

# Results (@@JOB_BASE_NAME@@ #@@BUILD_NUMBER@@ @@TIMESTAMP@@)
## Summary
### Prepare Test
| Scenario | Minimal | Median | Maximal |
| :--- | ---: | ---: | ---: |
| `open-login-page-time` | @@OPEN_LOGIN_PAGE_TIME_MIN@@ ms | @@OPEN_LOGIN_PAGE_TIME_MEDIAN@@ ms | @@OPEN_LOGIN_PAGE_TIME_MAX@@ ms |
| `login-time` | @@LOGIN_TIME_MIN@@ ms | @@LOGIN_TIME_MEDIAN@@ ms | @@LOGIN_TIME_MAX@@ ms |

### Load Test
| Scenario | Minimal | Median | Maximal |
| :--- | ---: | ---: | ---: |
|`auth-api-user`| @@AUTH_API_USER_MIN@@ ms | @@AUTH_API_USER_MEDIAN@@ ms | @@AUTH_API_USER_MAX@@ ms |
|`auth-api-token-refresh`| @@AUTH_API_TOKEN_REFRESH_MIN@@ ms | @@AUTH_API_TOKEN_REFRESH_MEDIAN@@ ms | @@AUTH_API_TOKEN_REFRESH_MAX@@ ms |
|`auth-api-user-github-token`| @@AUTH_API_USER_GITHUB_TOKEN_MIN@@ ms | @@AUTH_API_USER_GITHUB_TOKEN_MEDIAN@@ ms | @@AUTH_API_USER_GITHUB_TOKEN_MAX@@ ms |
|`api-user-by-id`| @@API_USER_BY_ID_MIN@@ ms | @@API_USER_BY_ID_MEDIAN@@ ms | @@API_USER_BY_ID_MAX@@ ms |
|`api-user-by-name`| @@API_USER_BY_NAME_MIN@@ ms | @@API_USER_BY_NAME_MEDIAN@@ ms | @@API_USER_BY_NAME_MAX@@ ms |

## Test charts

### Prepare Test
#### `open-login-page-time`
![open-login-page-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-open-login-page-time.png)
#### `login-time`
![login-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-login-time.png)

### Load Test
#### `auth-api-user` Response Time
![auth-api-user-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-response-time.png)
![auth-api-user-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-minimal-response-time.png)
![auth-api-user-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-median-response-time.png)
![auth-api-user-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-maximal-response-time.png)
![auth-api-user-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-average-response-time.png)
#### `auth-api-token-refresh` Response Time
![auth-api-token-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-response-time.png)
![auth-api-token-minimal-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-minimal-response-time.png)
![auth-api-token-median-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-median-response-time.png)
![auth-api-token-maximal-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-maximal-response-time.png)
![auth-api-token-average-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-average-response-time.png)
#### `auth-api-user-github-token` Response Time
![auth-api-user-github-token-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-response-time.png)
![auth-api-user-github-token-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-minimal-response-time.png)
![auth-api-user-github-token-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-median-response-time.png)
![auth-api-user-github-token-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-maximal-response-time.png)
![auth-api-user-github-token-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-average-response-time.png)
#### `api-user-by-id` Response Time
![api-user-by-id-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-response-time.png)
![api-user-by-id-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-minimal-response-time.png)
![api-user-by-id-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-median-response-time.png)
![api-user-by-id-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-maximal-response-time.png)
![api-user-by-id-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-average-response-time.png)
####  `api-user-by-name` Response Time
![api-user-by-name-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-response-time.png)
![api-user-by-name-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-minimal-response-time.png)
![api-user-by-name-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-median-response-time.png)
![api-user-by-name-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-maximal-response-time.png)
![api-user-by-name-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-average-response-time.png)