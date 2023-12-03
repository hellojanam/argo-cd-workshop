# Setting Up a Highly Available (HA) Argo CD in a Kubernetes Cluster

Table of Contents
- [Introduction](#introduction)
- [What is Argo CD?](#what-is-argo-cd)
- [Repository and Folder Structure](#repository-and-folder-structure)
- [Prerequisites](#prerequisites)
- [Install Argo CD](#install-argo-cd)
- [Access the Argo CD UI](#access-the-argo-cd-ui)
- [Login to Argo CD](#login-to-argo-cd)
- [Connect a Git/Charts Repository](#connect-a-gitcharts-repository)
- [Create an Argo-CD Application Helm Chart](#create-an-argo-cd-application-helm-chart)
- [Create an Application Controller in Argo-UI](#create-an-application-controller-in-argo-ui)
- [Format to Use Application Values File with Argo CD Setup](#format-to-use-application-values-file-with-argo-cd-setup)
- [Conclusion](#conclusion)

## introduction
Deploying applications to Kubernetes can be complex. Thankfully, tools like Argo CD make it easier to practice GitOps and continuous delivery on Kubernetes. In this guide, we'll walk through how to set up Argo CD and start automating deployments.

## What is Argo CD?

Argo CD is an open-source GitOps tool for deploying applications to Kubernetes. It works by using Git as the single source of truth for both infrastructure and application code. Argo CD can then monitor your Git repository and automatically sync any changes to your Kubernetes cluster, enabling a declarative way to release new versions. Instead of running scripts or manually updating config, you just push code changes to Git, and Argo CD handles the rest.

## Repository and Folder Structure

To set up Argo CD, you can use the following repository and folder structure:

- Main Repository: [cloudhero.io/infra/argo-cd.git](https://github.com/cloudhero.io/infra/argo-cd.git)
  - `target-envs`
    - `Templates`: Contains Argo CD application manifests.
    - `Chart.yaml`: Chart information.
    - `Values.yaml`: Values for the Helm chart of the Argo application.
  - `Kubernetes`
    - `Values`
      - `Chart.yaml`: Specifies which chart to use for the application and its version.

## Prerequisites

Before we get started, make sure you have:

- A Kubernetes cluster up and running. Minikube works well for local testing.
- `kubectl` installed and configured.
- Helm installed on your machine. We'll use this to install Argo CD.
- Your application Helm charts deployed in Chartmuseum or any other services. I assume you have already installed Chartmuseum and pushed your charts to Chartmuseum. If not, do that first.

## Install Argo CD

Let's start by installing Argo CD into our cluster. We'll use the official Argo Helm charts, which makes this pretty easy. First, add the Argo CD Helm repo:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
```
Then create a namespace to install Argo CD into:
```bash
kubectl create namespace argo-cd
```
We have prepared the values file with Highly Available Argo CD Setup. It uses Redis and HA-Proxy to give a Highly available Argo CD setup. You can find the Values.yaml here.

https://github.com/cloud-hero/captain/tree/master/argo-cd/argo-cd-helm-values

Now we can run the install command:

```bash
helm install argocd argo/argo-cd -n argo-cd -f values.yaml
```

Check if all pods are up and running:

```bash
kubectl get pods -n argo-cd
```

## Access the Argo CD UI

By default, the Argo CD API server is not exposed publicly. For local access, we can create a port-forward:

```bash
kubectl port-forward svc/argocd-server -n argo-cd 8080:443
```

This exposes the API server on localhost port 8080. We can now access the Argo CD UI at [http://localhost:8080](http://localhost:8080).

For exposing the Argo UI for production, we can use virtual service and gateway of Istio. You can find a sample Ingress for Istio [here](https://github.com/cloud-hero/captain/tree/master/argo-cd/ingress).

## Login to Argo CD

The default username is admin, and the password is auto-generated during install. You can retrieve it with:

```bash
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Make sure to change this password after logging in the first time. The Argo CD dashboard should now be accessible! Next, we'll connect it to our repository.

## Connect a Git/Charts Repository

Argo CD relies on Git repos to store the application manifests it will deploy. Under "Settings," click "Connect Repo" and enter the repo URL (for example, your GitHub repo) along with access credentials. Argo CD also supports SSH repos if needed. If you are using Chartmuseum or any other external source for Helm charts, don't forget to connect your Chartmuseum as well. Now Argo CD can access the manifests and deploy them.

## Create an Argo-CD Application Helm Chart

In cloudhero, we create Helm charts for the set of applications to be deployed in Argo CD. It reduces the time to create a new application in Argo CD each time a new module is added or a new application needs to be added. Here, the process is quite simple. We create an Application controller that will point to where the Argo CD application Helm chart resides. When we update anything on that Helm chart repo, the controller will auto apply it in Argo CD. Argo CD will now monitor the Git repo and automatically sync any changes to the cluster. We can also manually sync if needed.

You can create a separate Git repo for Argo CD-related setup. In an Argo CD repo, you can create a folder called `target-envs` and keep the Argo CD application charts in that folder.

Link for a sample Argo CD application chart: [Argo CD Application Chart](https://github.com/cloud-hero/captain/tree/master/argo-cd/application-chart)

In this chart, you can add the environments according to your requirements. Each environment can have multiple applications. Like in a dev environment, we can have API, worker, crons, services, and so on.

Note: you can remove the notification annotations if you don't want to be alerted. If you want to receive alerts, please follow this guide to set up the notifications: [Argo CD Notifications](https://argocd-notifications.readthedocs.io/en/stable/services/slack/).

## Create an Application Controller in Argo-UI

The Application Controller is one of the core components of Argo CD responsible for continuously reconciling application state in the cluster to match the desired state defined in the Argo CD applications chart. The Application Controller operates in a continuous control loop to maintain application health and sync status. It controls all the applications that will be added in the `target-envs` folder. It keeps track of all the applications added, modified, or deleted. You don't need to manually log in to Argo-UI and edit, modify, or delete them. Just do that in the `target-envs` folder/repo, and the apps controller will handle the rest of the work for you.

Sample application controller YAML: [Application Controller YAML](https://github.com/cloud-hero/captain/blob/master/argo-cd/apps-controller.yaml)

To create an apps controller, follow these steps:

1. Click on the "Applications" tab in the Argo CD UI.
2. Click "New Application."
3. Click “Edit as YAML.”
4. Copy the contents from the above link.
5. Click "Create."

It will create the Application Controller and the applications defined in its `target-envs` repo.

## Format to Use Application Values File with Argo CD Setup

If you follow all the above steps, you will be able to set up a HA Argo CD setup with a fully automatic application controller setup. To make applications work with Helm charts, you need to pass the application `values.yaml` and its location along with the chart to use and its version.

The format is a values folder that can contain `Chart.yaml` and `Values.yaml` on it. `Chart.yaml` describes which chart to use and the version of the chart. `Values.yaml` is values for the application.

```
/Values/
  ↳ Chart.yaml
  ↳ Values.yaml
```

The sample for values files is: [Sample Values Files](https://github.com/cloud-hero/captain/tree/master/argo-cd/kubernetes-values-sample)

## Conclusion

This process sets up an Argo CD in Kubernetes and a working Argo CD setup with the values and charts in a different repo. Adding a new module or environment now can be easier; approximately 5 minutes is enough.
```
