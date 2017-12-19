# Opehshift.io Planner Performance Probe

An utility to login Openshift.io users into Planner

Prerequisities
--------------

Chrome or [Chromium browser](https://www.chromium.org/Home) with headless feature and [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) needs to be installed where it is run (for Fedora/RHEL/CentOS):
```
$ sudo yum install chromium chromium-headless chromedriver
```

Usage
-----

To run, provide a line separated list of users ("user=password") in the environment variable called USERS_PROPERTIES and execute:
```
$ mvn clean compile exec:java (-Dserver.host=...) (-Dserver.port=...) (-Diterations=1)
```

where:
 * `server.host` = openshift.io address (e.g. "`https://openshift.io`")
 * `server.port` = a port number of the service endpoints (e.g. "`443`")
 * `iterations` = a number of test iterations for each user to perform (default is `1`)

Example:
```
$ mvn clean compile exec:java -Dserver.host=https://openshift.io -Dserver.port=443 -Diterations=10
```
