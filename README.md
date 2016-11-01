# Static IP www. redirect service

## Design guidelines for clusters
1. We don't ever want our clients to use static IP-addresses for our servers in their dns.
2. To avoid static IP addresses we ask our clients to use CNAME records instead.
3. We want to support bare domains as well

## Problem
Many of our clients want to control their own dns. Usually they use quite old service providers which don't support CNAME records for bare domains like `client.com`.

## Solutions
### 1: Change DNS provider to better one
In order to use bare domain addresses for the web applications the client needs to move their dns to one of these providers:

* https://dnssimple.com ( Feature name: ALIAS)
* https://www.cloudflare.com ( Feature name: CNAME flattening)

These providers do have support CNAME style behaviour for bare domains. They don't actually support cname because it's against [RFC 1034 section 3.6.2](http://www.faqs.org/rfcs/rfc1034.html). But they resolve CNAME after TTL is inded and automatically add A record which has all the IP-addresses from the CNAME.

### 2: Redirect bare domain to www. with static IP servers

When solution 1 isn't possible for the client we can use servers which listen to any http_host like `client.com` and redirect them to `www.client.com`.

This is quite hard to achieve in the long run since we want to achieve really long standing processes. This means that we would prefer not to do reboots and system updates ourselves.

Ideally this would be lambda function with this nginx spec:
```
server {
    listen       80  default_server;
    return       301 www.$http_host;
}
```

During our research on october 2016 aws lambda or google cloud functions didn't support static IP-addresses. We still didn't want to maintain our own servers for such a small task. So next option was to use containers. After searching for container service with static IP-address support we decided to use Google container engine

## Setup
We followed this guide from Google: https://cloud.google.com/container-engine/docs/tutorials/http-balancer

### Create new project for redirect cluster
Create new project from admin console and enable Compute api for the project: https://console.developers.google.com/apis/api/compute_component/overview?project=YOUR_PROJECT_ID

Then run these commands
```
$ gcloud config set project my-redirect-project-id
$ export ZONE="europe-west-1"
$ export CLUSTER_NAME="www-redirector"
$ gcloud container clusters create $CLUSTER_NAME --zone $ZONE
```
