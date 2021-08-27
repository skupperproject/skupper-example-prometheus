# Multi-cluster Prometheus Metrics Gathering Demo

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

Top complete this tutorial, do the following:

* [Prerequisites](#prerequisites)
* [Step 1: Set up the demo](#step-1-set-up-the-demo)
* [Step 2: Deploy the Virtual Application Network](#step-2-deploy-the-virtual-application-network)
* [Step 3: Deploy the Metrics Generators](#step-3-deploy-the-metrics-generators)
* [Step 4: Deploy the Prometheus Server](#step-4-deploy-the-prometheus-server)
* [Step 5: Expose the Metrics Deployments to the Virtual Application Network](#step-5-expose-the-metrics-deployments-to-the-virtual-application-network)
* [Step 6: Access the Prometheus Web UI](#step-6-access-the-prometheus-web-ui)
* [Cleaning up](#cleaning-up)
* [Next steps](#next-steps)

## Prerequisites

* The `kubectl` command-line tool, version 1.15 or later ([installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/))
* The `skupper` command-line tool, version 0.8.1 or later ([installation guide](https://skupper.io/start/index.html#step-1-install-the-skupper-command-line-tool-in-your-environment))

The basis for this demonstration is to emulate the distribution of application services across both private and public clusters and for the ability to gather generated metrics across a Virtual Application Network. As an example, the cluster deployment might be comprised of:

* A private cloud cluster running on your local machine
* Two public cloud clusters running in public cloud providers

While the detailed steps are not included here, this demonstration can alternatively be performed with three separate namespaces on a single cluster.

## Step 1: Set up the demo

1. On your local machine, make a directory for this tutorial and clone the example repo:

   ```bash
   mkdir ~/prom-demo
   cd ~/prom-demo
   git clone https://github.com/skupperproject/skupper-example-prometheus.git
   ```
2. Prepare the target clusters.

   1. On your local machine, log in to each cluster in a separate terminal session.
   2. In each cluster, create a namespace to use for the demo.
      1. The namespaces to be created are: public1, public2 and private1.
   3. In each cluster, set the kubectl config context to use the demo namespace [(see kubectl cheat sheet for more information)](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
   ```bash
   kubectl config set-context --current --namespace <namespace>
   ```
## Step 2: Deploy the Virtual Application Network

On each cluster, using the `skupper` tool, define the Virtual Application Network and the connectivity for the peer clusters.

1. In the terminal for the first public cluster (**namespace: public1**), deploy the **public1** application router. Create a connection token for connections from the peer clusters.

   ```bash
   kubectl create namespace public1
   skupper init --site-name public1
   skupper token create public1-token.yaml --uses 2
   ```

2. In the terminal for the second public cluster (**namespace: public2**), deploy the **public2** application router, create a connection token for connections from the peer clusters  and link to the **public1** cluster:

   ```bash
   kubectl create namespace public2
   skupper init --site-name public2
   skupper token create public2-token.yaml
   skupper link create public1-token.yaml
   ```

3. In the terminal for the private cluster (**namespace: private1**), deploy the **private1** application router and create its links to the **public1** and **public2** clusters

   ```bash
   kubectl create namespace private1
   skupper init --site-name private1
   skupper link create public1-token.yaml
   skupper link create public2-token.yaml
   ```

4. In each of the cluster terminals, verify connectivity has been established

   ```bash
   skupper link status
   ```

## Step 3: Deploy the Metrics Generators

After creating the Virtual Application Network, deploy the Metrics Generators on one of the public clusters and the private cluster.

1. In the terminal for the **private1** cluster, deploy the first metrics generator (a):

   ```bash
   kubectl apply -f ~/prom-demo/skupper-example-prometheus/metrics-deployment-a.yaml
   ```

2. In the terminal for the **public1** cluster, deploy the second metrics generator (b):

   ```bash
   kubectl apply -f ~/prom-demo/skupper-example-prometheus/metrics-deployment-b.yaml
   ```

## Step 4: Deploy the Prometheus server

1. In the terminal for the **public2** cluster, deploy the Prometheus server:

   **NOTE:** In case you are not using **public2** as the namespace for your public2 cluster,
   you must update the namespace defined in prometheus-deployment.yaml from public2 to your namespace name.

   ```bash
   kubectl apply -f ~/prom-demo/skupper-example-prometheus/prometheus-deployment.yaml
   ```

## Step 5: Expose the Metrics Deployments to the Virtual Application Network

1. In the terminal for the **private1** cluster, expose the first metrics generator (a) deployment:

   ```bash
   skupper expose deployment metrics-a --address metrics-a --port 8080 --protocol tcp --target-port 8080
   skupper service label metrics-a app=metrics
   ```

2. In the terminal for the **public1** cluster, expose the second metrics generator (b) deployment:

   ```bash
   skupper expose deployment metrics-b --address metrics-b --port 8080 --protocol tcp --target-port 8080
   skupper service label metrics-b app=metrics
   ```

## Step 6: Access the Prometheus Web UI

1. In the terminal for the **public2** cluster, expose the Prometheus server:

   ```bash
   skupper expose deployment prometheus --address prometheus --port 9090 --protocol http --target-port 9090
   ```

2. In the terminal for the **private1** cluser, start a firefox browser and access the Prometheus UI

    ```bash
    /usr/bin/firefox --new-window  "http://$(kubectl get service prometheus -o=jsonpath='{.spec.clusterIP}'):9090/"
    ```

3. In the Prometheus UI, navigate to *Status->Targets* and verify that the metric endpoints are in the *UP* state

4. In the Prometheus UI, navigate to the *Graph* tab and insert the following expression to execute

   ```bash
   avg(rate(rpc_durations_seconds_count[1m])) by (job, service)
   ```

Observe the metrics data in either the *Console* or *Graph* view provided in the UI.

## Cleaning Up

Restore your cluster environment by returning the resources created in the demonstration. On each cluster, delete the demo resources and the skupper network:

1. In the terminal for the **private1** cluster, delete the resources:

   ```bash
   skupper unexpose deployment metrics-a
   kubectl delete -f ~/prom-demo/skupper-example-prometheus/metrics-deployment-a.yaml
   skupper delete
   kubectl delete ns private1
   ```

2. In the terminal for the **public1** cluster, delete the resources:

   ```bash
   skupper unexpose deployment metrics-b
   kubectl delete -f ~/prom-demo/skupper-example-prometheus/metrics-deployment-b.yaml
   skupper delete
   kubectl delete ns public1
   ```

3. In the terminal for the **public2** cluster, delete the resources:

   ```bash
   skupper unexpose deployment prometheus
   kubectl delete -f ~/prom-demo/skupper-example-prometheus/prometheus-deployment.yaml
   skupper delete
   kubectl delete ns public2
   ```

## Next Steps

 - [Find more examples](https://skupper.io/examples/)
