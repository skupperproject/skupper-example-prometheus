<!-- NOTE: This file is generated from skewer.yaml.  Do not edit it directly. -->

# Multi-cluster Prometheus Metrics Gathering Demo

[![main](https://github.com/pwright/skupper-example-prometheus/actions/workflows/main.yaml/badge.svg)](https://github.com/pwright/skupper-example-prometheus/actions/workflows/main.yaml)

This example is part of a [suite of examples][examples] showing the
different ways you can use [Skupper][website] to connect services
across cloud providers, data centers, and edge sites.

[website]: https://skupper.io/
[examples]: https://skupper.io/examples/index.html

#### Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Step 1: Install the Skupper command-line tool](#step-1-install-the-skupper-command-line-tool)
* [Step 2: Access your Kubernetes clusters](#step-2-access-your-kubernetes-clusters)
* [Step 3: Install Skupper on your Kubernetes clusters](#step-3-install-skupper-on-your-kubernetes-clusters)
* [Step 4: Create your Kubernetes namespaces](#step-4-create-your-kubernetes-namespaces)
* [Step 5: Create your sites](#step-5-create-your-sites)
* [Step 6: Link your sites](#step-6-link-your-sites)
* [Step 7: Deploy the Metrics Generators](#step-7-deploy-the-metrics-generators)
* [Step 8: Deploy the Prometheus Server on the other public cluster.](#step-8-deploy-the-prometheus-server-on-the-other-public-cluster)
* [Step 9: Expose the Metrics Deployments to the Virtual Application Network](#step-9-expose-the-metrics-deployments-to-the-virtual-application-network)
* [Step 10: Label services as Prometheus dedicated collection points](#step-10-label-services-as-prometheus-dedicated-collection-points)
* [Step 11: Access the Prometheus Web UI](#step-11-access-the-prometheus-web-ui)
* [Step 12: Verify Metrics](#step-12-verify-metrics)
* [Cleaning up](#cleaning-up)
* [Next steps](#next-steps)
* [About this example](#about-this-example)

## Overview

This tutorial demonstrates how to deploy metric generators across
multiple Kubernetes clusters that are located in different public and
private cloud providers and to additionally deploy the
[Prometheus](https://prometheus.io) monitoring system to gather
metrics across multiple clusters, discovering the endpoints to be
scraped dynamically, as soon as services are exposed through the
Skupper Virtual Application Network.

In this tutorial, you will create a Virtual Application Network that
enables communications across the public and private clusters. You
will then deploy the metric generators and Prometheus server to individual
clusters. You will then access the Prometheus server Web UI to
browse targets, query and graph the collected metrics.

## Prerequisites

* Access to at least one Kubernetes cluster, from [any provider you
  choose][kube-providers].

* The `kubectl` command-line tool, version 1.15 or later
  ([installation guide][install-kubectl]).

[kube-providers]: https://skupper.io/start/kubernetes.html
[install-kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Step 1: Install the Skupper command-line tool

This example uses the Skupper command-line tool to create Skupper
resources.  You need to install the `skupper` command only once
for each development environment.

On Linux or Mac, you can use the install script (inspect it
[here][install-script]) to download and extract the command:

~~~ shell
curl https://skupper.io/v2/install.sh | sh
~~~

The script installs the command under your home directory.  It
prompts you to add the command to your path if necessary.

For Windows and other installation options, see [Installing
Skupper][install-docs].

[install-script]: https://github.com/skupperproject/skupper-website/blob/main/input/install.sh
[install-docs]: https://skupper.io/install/

## Step 2: Access your Kubernetes clusters

Skupper is designed for use with multiple Kubernetes clusters.
The `skupper` and `kubectl` commands use your
[kubeconfig][kubeconfig] and current context to select the cluster
and namespace where they operate.

[kubeconfig]: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/

This example uses multiple cluster contexts at once. The
`KUBECONFIG` environment variable tells `skupper` and `kubectl`
which kubeconfig to use.

For each cluster, open a new terminal window.  In each terminal,
set the `KUBECONFIG` environment variable to a different path and
log in to your cluster.

_**Public1:**_

~~~ shell
export KUBECONFIG=~/.kube/config-public1
<provider-specific login command>
~~~

_**Public2:**_

~~~ shell
export KUBECONFIG=~/.kube/config-public2
<provider-specific login command>
~~~

_**Private1:**_

~~~ shell
export KUBECONFIG=~/.kube/config-private1
<provider-specific login command>
~~~

**Note:** The login procedure varies by provider.

## Step 3: Install Skupper on your Kubernetes clusters

Using Skupper on Kubernetes requires the installation of the
Skupper custom resource definitions (CRDs) and the Skupper
controller.

For each cluster, use `kubectl apply` with the Skupper
installation YAML to install the CRDs and controller.

_**Public1:**_

~~~ shell
kubectl apply -f https://skupper.io/v2/install.yaml
~~~

_**Public2:**_

~~~ shell
kubectl apply -f https://skupper.io/v2/install.yaml
~~~

_**Private1:**_

~~~ shell
kubectl apply -f https://skupper.io/v2/install.yaml
~~~

## Step 4: Create your Kubernetes namespaces

The example application has different components deployed to
different Kubernetes namespaces.  To set up our example, we need
to create the namespaces.

For each cluster, use `kubectl create namespace` and `kubectl
config set-context` to create the namespace you wish to use and
set the namespace on your current context.

_**Public1:**_

~~~ shell
kubectl create namespace public1
kubectl config set-context --current --namespace public1
~~~

_**Public2:**_

~~~ shell
kubectl create namespace public2
kubectl config set-context --current --namespace public2
~~~

_**Private1:**_

~~~ shell
kubectl create namespace private1
kubectl config set-context --current --namespace private1
~~~

## Step 5: Create your sites

A Skupper _site_ is a location where components of your
application are running.  Sites are linked together to form a
network for your application.  In Kubernetes, a site is associated
with a namespace.

Use the kubectl apply command to declaratively create sites in the kubernetes
namespaces. This deploys the Skupper router. Then use kubectl get site to see
the outcome.

**Note:** If you are using Minikube, you need to [start minikube
tunnel][minikube-tunnel] before creating sites.

[minikube-tunnel]: https://skupper.io/start/minikube.html#running-minikube-tunnel

_**Public1:**_

~~~ shell
kubectl apply -f ./public1-crs/site.yaml
kubectl wait --for condition=Ready --timeout=60s site/public1
~~~

_Sample output:_

~~~ console
$ kubectl wait --for condition=Ready --timeout=60s site/public1
site.skupper.io/public1 created
site.skupper.io/public1 condition met
~~~

_**Public2:**_

~~~ shell
kubectl apply -f ./public2-crs/site.yaml
kubectl wait --for condition=Ready --timeout=60s site/public2
~~~

_Sample output:_

~~~ console
$ kubectl wait --for condition=Ready --timeout=60s site/public2
site.skupper.io/public2 created
site.skupper.io/public2 condition met
~~~

_**Private1:**_

~~~ shell
kubectl apply -f ./private1-crs/site.yaml
kubectl wait --for condition=Ready --timeout=60s site/private1
~~~

_Sample output:_

~~~ console
$ kubectl wait --for condition=Ready --timeout=60s site/private1
site.skupper.io/private1 created
site.skupper.io/private1 condition met
~~~

## Step 6: Link your sites

A Skupper _link_ is a channel for communication between two sites.
Links serve as a transport for application connections and
requests.

Creating a link requires use of two `skupper` commands in
conjunction, `skupper token issue` and `skupper token redeem`.

The `skupper token issue` command generates a secret token that
signifies permission to create a link.  The token also carries the
link details.  Then, in a remote site, The `skupper token
redeem` command uses the token to create a link to the site
that generated it.

**Note:** The link token is truly a *secret*.  Anyone who has the
token can link to your site.  Make sure that only those you trust
have access to it.

First, use `skupper token issue` in public1 to generate the
token.  Then, use `skupper token redeem` in public2 to link the
sites.  Using the flag redemptions-allowed specifies how many tokens
are created.  In this scenario public2 and private1 will connect to
public1 so we will need two tokens.

_**Public1:**_

~~~ shell
skupper token issue ~/public1.token --redemptions-allowed 2
~~~

_**Public2:**_

~~~ shell
skupper token redeem ~/public1.token
skupper token issue ~/public2.token
~~~

_**Private1:**_

~~~ shell
skupper token redeem ~/public1.token
skupper token redeem ~/public2.token
~~~

If your terminal sessions are on different machines, you may need
to use `scp` or a similar tool to transfer the token securely.  By
default, tokens expire after a single use or 15 minutes after
creation.

## Step 7: Deploy the Metrics Generators

After creating the Skupper network, deploy the Metrics Generators
on one of the public clusters and the private cluster.

_**Private1:**_

~~~ shell
kubectl apply -f ./private1-crs/metrics-deployment-a.yaml
~~~

_Sample output:_

~~~ console
$ kubectl apply -f ./private1-crs/metrics-deployment-a.yaml
deployment.apps/metrics-a created
~~~

_**Public1:**_

~~~ shell
kubectl apply -f ./public1-crs/metrics-deployment-b.yaml
~~~

_Sample output:_

~~~ console
$ kubectl apply -f ./public1-crs/metrics-deployment-b.yaml
deployment.apps/metrics-b created
~~~

## Step 8: Deploy the Prometheus Server on the other public cluster.

Deploy the Prometheus server in the public2 cluster.

_**Public2:**_

~~~ shell
kubectl apply -f ./public2-crs/prometheus-deployment.yaml
~~~

_Sample output:_

~~~ console
$ kubectl apply -f ./public2-crs/prometheus-deployment.yaml
role.rbac.authorization.k8s.io/prometheus created
serviceaccount/prometheus created
rolebinding.rbac.authorization.k8s.io/prometheus created
configmap/prometheus-conf created
deployment.apps/prometheus created
~~~

## Step 9: Expose the Metrics Deployments to the Virtual Application Network

Create Skupper listeners and connectors to expose the metric generator deployments in each namespace.

_**Private1:**_

~~~ shell
kubectl apply -f ./private1-crs/listener.yaml
kubectl apply -f ./private1-crs/connector.yaml
~~~

_Sample output:_

~~~ console
$ kubectl apply -f ./private1-crs/connector.yaml
listener.skupper.io/prometheus created
connector.skupper.io/metric-a created
~~~

_**Public1:**_

~~~ shell
kubectl apply -f ./public1-crs/listener.yaml
kubectl apply -f ./public1-crs/connector.yaml
~~~

_Sample output:_

~~~ console
$ kubectl apply -f ./public1-crs/connector.yaml
listener.skupper.io/prometheus created
connector.skupper.io/metric-b created
~~~

_**Public2:**_

~~~ shell
kubectl apply -f ./public2-crs/listener.yaml
kubectl apply -f ./public2-crs/connector.yaml
~~~

_Sample output:_

~~~ console
$ kubectl apply -f ./public2-crs/connector.yaml
listener.skupper.io/metrics-a created
listener.skupper.io/metrics-b created
connector.skupper.io/prometheus created
~~~

## Step 10: Label services as Prometheus dedicated collection points

In Prometheus, a service label with "app=metrics" indicates that
the service is specifically designed to expose metrics for
monitoring purposes. This label allows Prometheus to easily identify
and scrape data from that service to gather performance and health
information.

_**Public2:**_

~~~ shell
kubectl label service/metrics-a app=metrics
kubectl label service/metrics-b app=metrics
~~~

_Sample output:_

~~~ console
$ kubectl label service/metrics-b app=metrics
service/metrics-a labeled
service/metrics-b labeled
~~~

## Step 11: Access the Prometheus Web UI

In a browser access the Prometheus UI at http://{ip}:9090 where ip is output of following command:

_**Private1:**_

~~~ shell
kubectl get service prometheus -o=jsonpath='{.spec.clusterIP}')
~~~

In the Prometheus UI, navigate to Status->Target health and verify that the metric endpoints are in the UP state

## Step 12: Verify Metrics

In the Prometheus UI, navigate to the Query tab and insert the following expression to execute in the + Add query and click execute:
`avg(rate(rpc_durations_seconds_count[1m])) by (job, service)`

Observe the metrics data in either the Table or Graph view provided in the UI.

## Cleaning up

To remove Skupper and the other resources from this exercise, use
the following commands.

_**Private1:**_

~~~ shell
skupper site delete --all
kubectl delete -f ./private1-crs/metrics-deployment-a.yaml
~~~

_**Public1:**_

~~~ shell
skupper site delete --all
kubectl delete -f ./public1-crs/metrics-deployment-b.yaml
~~~

_**Public2:**_

~~~ shell
skupper site delete --all
kubectl delete -f ./public2-crs/prometheus-deployment.yaml
~~~

## Next steps

Check out the other [examples][examples] on the Skupper website.

## About this example

This example was produced using [Skewer][skewer], a library for
documenting and testing Skupper examples.

[skewer]: https://github.com/skupperproject/skewer

Skewer provides utility functions for generating the README and
running the example steps.  Use the `./plano` command in the project
root to see what is available.

To quickly stand up the example using Minikube, try the `./plano demo`
command.
