# Results (@@JOB_BASE_NAME@@ #@@BUILD_NUMBER@@ @@TIMESTAMP@@)
## Summary
The following tables show the final results taken and computed from a single test run - i.e. after and by running the login phase and the 5 minutes of the load phase.

The summary results of each run are uploaded to the
[Zabbix](https://zabbix.devshift.net:9443/zabbix/screens.php?elementid=32&fullscreen=1)
monitoring system to track the results' history.

### Prepare Test
| Scenario | Minimal (Auth) | Minimal (OAuth2) | Median (Auth) | Median (OAuth2) | Maximal (Auth) |Maximal (OAuth2) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| `open-login-page-time` | @@OPEN_LOGIN_PAGE_TIME_MIN@@ ms | @@OAUTH2_OPEN_LOGIN_PAGE_TIME_MIN@@ ms | @@OPEN_LOGIN_PAGE_TIME_MEDIAN@@ ms | @@OAUTH2_OPEN_LOGIN_PAGE_TIME_MEDIAN@@ ms | @@OPEN_LOGIN_PAGE_TIME_MAX@@ ms | @@OAUTH2_OPEN_LOGIN_PAGE_TIME_MAX@@ ms |
| `get-code-time` | - | @@OAUTH2_GET_CODE_TIME_MIN@@ ms | - | @@OAUTH2_GET_CODE_TIME_MEDIAN@@ ms | - | @@OAUTH2_GET_CODE_TIME_MAX@@ ms |
| `get-token-time` | - | @@OAUTH2_GET_TOKEN_TIME_MIN@@ ms | - | @@OAUTH2_GET_TOKEN_TIME_MEDIAN@@ ms | - | @@OAUTH2_GET_TOKEN_TIME_MAX@@ ms |
| `login-time` | @@LOGIN_TIME_MIN@@ ms | @@OAUTH2_LOGIN_TIME_MIN@@ ms | @@LOGIN_TIME_MEDIAN@@ ms | @@OAUTH2_LOGIN_TIME_MEDIAN@@ ms | @@LOGIN_TIME_MAX@@ ms | @@OAUTH2_LOGIN_TIME_MAX@@ ms |

### Load Test
| Scenario | Minimal | Median | Maximal | Average | Failed |
| :--- | ---: | ---: | ---: | ---: | ---: |
|`auth-api-user`| @@AUTH_API_USER_MIN@@ ms | @@AUTH_API_USER_MEDIAN@@ ms | @@AUTH_API_USER_MAX@@ ms | @@AUTH_API_USER_AVERAGE@@ ms | @@AUTH_API_USER_FAILED@@ |
|`auth-api-token-refresh`| @@AUTH_API_TOKEN_REFRESH_MIN@@ ms | @@AUTH_API_TOKEN_REFRESH_MEDIAN@@ ms | @@AUTH_API_TOKEN_REFRESH_MAX@@ ms | @@AUTH_API_TOKEN_REFRESH_AVERAGE@@ ms | @@AUTH_API_TOKEN_REFRESH_FAILED@@ |
|`auth-api-user-github-token`| @@AUTH_API_USER_GITHUB_TOKEN_MIN@@ ms | @@AUTH_API_USER_GITHUB_TOKEN_MEDIAN@@ ms | @@AUTH_API_USER_GITHUB_TOKEN_MAX@@ ms | @@AUTH_API_USER_GITHUB_TOKEN_AVERAGE@@ ms | @@AUTH_API_USER_GITHUB_TOKEN_FAILED@@ |
|`api-user-by-id`| @@API_USER_BY_ID_MIN@@ ms | @@API_USER_BY_ID_MEDIAN@@ ms | @@API_USER_BY_ID_MAX@@ ms | @@API_USER_BY_ID_AVERAGE@@ ms | @@API_USER_BY_ID_FAILED@@ |
|`api-user-by-name`| @@API_USER_BY_NAME_MIN@@ ms | @@API_USER_BY_NAME_MEDIAN@@ ms | @@API_USER_BY_NAME_MAX@@ ms | @@API_USER_BY_NAME_AVERAGE@@ ms | @@API_USER_BY_NAME_FAILED@@ |

## Test charts
The charts bellow show the whole duration of all the phases for each scenario - i.e. what lead to the final results shown above in the summary.

### Prepare Test
The following charts show the respective times of UI of each test user as they were logged in one by one.
So the first value in the chart is for the first user, the second value is for the second user and so on.

#### `open-login-page-time` (Auth)
![open-login-page-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-open-login-page-time.png)

#### `login-time` (Auth)
![login-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-login-time.png)

#### `open-login-page-time` (OAuth2)
![oauth-open-login-page-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-oauth2-open-login-page-time.png)

#### `get-code-time` (OAuth2)
![oauth2-get-code-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-oauth2-get-code-time.png)

#### `get-token-time` (OAuth2)
![oauth2-get-token-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-oauth2-get-token-time.png)

#### `login-time` (OAuth2)
![oauth2-login-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-oauth2-login-time.png)

### Load Test
In these charts, the value shown in each point of time is the metric (minimal, median, maximal and average value) of the response time
computed for a time window from the start to the respective point of time. So it is a floating metric.

That is the reason for the values of the maximals always go up.
#### `auth-api-user` Response Time
![auth-api-user-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-response-time.png)
![auth-api-user-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-minimal-response-time.png)
![auth-api-user-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-median-response-time.png)
![auth-api-user-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-maximal-response-time.png)
![auth-api-user-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-average-response-time.png)
![auth-api-user-rt-histo](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-rt-histo.png)
#### `auth-api-user` Failures
![auth-api-user-failures](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-failures.png)
#### `auth-api-token-refresh` Response Time
![auth-api-token-refresh-response-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-response-time.png)
![auth-api-token-refresh-minimal-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-minimal-response-time.png)
![auth-api-token-refresh-median-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-median-response-time.png)
![auth-api-token-refresh-maximal-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-maximal-response-time.png)
![auth-api-token-refresh-average-refresh-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-average-response-time.png)
![auth-api-token-refresh-histo](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-rt-histo.png)
#### `auth-api-token-refresh` Failures
![auth-api-token-refresh-failures](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-POST_auth-api-token-refresh-failures.png)
#### `auth-api-user-github-token` Response Time
![auth-api-user-github-token-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-response-time.png)
![auth-api-user-github-token-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-minimal-response-time.png)
![auth-api-user-github-token-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-median-response-time.png)
![auth-api-user-github-token-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-maximal-response-time.png)
![auth-api-user-github-token-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-average-response-time.png)
![auth-api-user-github-token-rt-histo](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-rt-histo.png)
#### `auth-api-user-github-token` Failures
![auth-api-user-github-token-failures](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_auth-api-user-github-token-failures.png)
#### `api-user-by-id` Response Time
![api-user-by-id-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-response-time.png)
![api-user-by-id-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-minimal-response-time.png)
![api-user-by-id-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-median-response-time.png)
![api-user-by-id-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-maximal-response-time.png)
![api-user-by-id-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-average-response-time.png)
![api-user-by-id-rt-histo](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-rt-histo.png)
#### `api-user-by-id` Failures
![api-user-by-id-failures](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-id-failures.png)
####  `api-user-by-name` Response Time
![api-user-by-name-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-response-time.png)
![api-user-by-name-minimal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-minimal-response-time.png)
![api-user-by-name-median-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-median-response-time.png)
![api-user-by-name-maximal-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-maximal-response-time.png)
![api-user-by-name-average-reponse-time](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-average-response-time.png)
![api-user-by-name-rt-histo](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-rt-histo.png)
#### `api-user-by-name` Failures
![api-user-by-name-failures](./@@JOB_BASE_NAME@@-@@BUILD_NUMBER@@-GET_api-user-by-name-failures.png)
