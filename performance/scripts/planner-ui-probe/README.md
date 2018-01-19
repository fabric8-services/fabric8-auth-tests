# Opehshift.io Planner Performance Probe
Simple test for logging Openshift.io users into the Planner UI using the Log In web and measuring how long does it take.

## Prerequisities

Chrome or [Chromium browser](https://www.chromium.org/Home) with headless feature and [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) needs to be installed where it is run (for Fedora/RHEL/CentOS):
```
$ sudo yum install chromium chromium-headless chromedriver
```
## How to run the test

To run the test, configure the test in `_setenv.sh` file and run the `run.sh` script.
