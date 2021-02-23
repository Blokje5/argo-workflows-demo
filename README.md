# Argo Workflows Demo

This repository contains all demos from my meetup talk about Argo Workflows.

## Requirements

In order to run the demos, the following tools are required:

- kind
- helm

## Working through the demo

In this repository you'll find several useful scripts and the code required to work through the examples. The Argo Workflow examples are ordered by number and stored in their own repositories.

### Installation

In order to run the demos we first need to install Argo Workflows. We will be using kind (or Kubernetes in Docker) to create a local cluster:

```console
make cluster
```

This will create a Kubernetes cluster locally. In the `01_installation/kind.yaml` file you can see we customize some settings of our kind cluster. This is to ensure we can reach applications running in our cluster via localhost without port-forwarding. 

Now we can install Argo Workflows:

```console
make install
```

We can now connect with the Argo UI by connecting to `localhost`. Traefik is used as the ingress controller, for those who are interested in the details.

> Note that in the file `01_installation/argo/workflow-executor.yaml` we override the default workflow executor. Workflow executors are used by Argo to e.g. pass artifacts from one container to another. The default workflow executor uses docker, however, this does not work in kind (for one it uses containerD). For more, see the [workflow executor documentation}(https://github.com/argoproj/argo-workflows/blob/master/docs/workflow-executors.md).
