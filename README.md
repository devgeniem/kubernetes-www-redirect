# Kubernetes www redirector
Redirect bare domains to www. easily with help from kubernetes and google.

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

Create the kubernetes cluster by running:
```
$ gcloud config set project my-redirect-project-id
$ export ZONE="europe-west-1"
$ export CLUSTER_NAME="www-redirector"
$ gcloud container clusters create $CLUSTER_NAME --zone $ZONE
```

Create nginx containers which redirect any request:
```
$ kubectl run www-redirect-nginx --image=devgeniem/nginx-www-redirect --port=80
```

Create a Container Engine service which exposes this nginx Pod on each node in your cluster
```
$ kubectl expose deployment www-redirect-nginx --target-port=80 --type=NodePort
```

Autoscale this container when cpu usage is over 70%:
```
$ kubectl autoscale deployment www-redirect-nginx --cpu-percent=70 --min=1 --max=10
```

Create load balancer and static IP-address for nginx containers:
```
$ kubectl create -f kube-ingress.yml
```

Wait that Google gives you static IP address:
```
$ kubectl get ingress --watch
NAME                   HOSTS     ADDRESS          PORTS     AGE
www-redirect-ingress   *         xxx.xxx.xxx.xxx   80        6m
```

Use the provided IP in the dns A record to redirect client.com -> www.client.com:
```
A @ xxx.xxx.xxx.xxx
```

## Updating the nginx image
This image is so simple that we doubt that this will need much updates. But for example if nginx rolls new security updates to nginx docker image our docker image [devgeniem/nginx-www-redirect](https://hub.docker.com/r/devgeniem/nginx-www-redirect/) will get updated automatically.

When this happens or if you want to make your own changes just run this command:
```
$ kubectl set image deployments/www-redirect-nginx www-redirect-nginx=devgeniem/nginx-www-redirect:latest
```

## Maintainers
[Onni Hakala](https://github.com/onnimonni)

## License
MIT

