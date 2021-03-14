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

We can now connect with the Argo UI by connecting to `localhost`. NGINX is used as the ingress controller, for those who are interested in the details.

> Note that in the file `01_installation/argo/workflow-executor.yaml` we override the default workflow executor. Workflow executors are used by Argo to e.g. pass artifacts from one container to another. The default workflow executor uses docker, however, this does not work in kind (for one it uses containerD). For more, see the [workflow executor documentation}(https://github.com/argoproj/argo-workflows/blob/master/docs/workflow-executors.md).


### First Workflow: Hello World

Let's start with a simple workflow:

```yml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: hello-world-parameters-
spec:
  entrypoint: whalesay
  arguments:
    parameters:
    - name: message
      value: hello world

  templates:
  - name: whalesay
    inputs:
      parameters:
      - name: message
    container:
      image: docker/whalesay
      command: [cowsay]
      args: ["{{inputs.parameters.message}}"]
```

It will execute the `whalesay` container and defines an optional workflow parameter, which is passed to the container as an input.

You can execute the workflow using:

```console
make hello
```

Once the container has completed execution, you can check the results using:

```console
kubectl logs hello-world-parameters-xx-yy -c main
```


## Multi-step Argo workflows

Argo supports running multi-step workflows, which are useful when crafting more complicated flows. Argo supports two styles for multi-step workflows: Steps and DAG syntax. Let's compare both by looking at an example (Examples can be found in the 03_pod_racing folder):

```yml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: dag-pod-racing-
spec:
  entrypoint: pod-racing
  templates:
  - name: bash
    inputs:
      parameters:
      - name: args
    container:
      image: busybox:latest
      command: [sh, -c]
      args: ["{{inputs.parameters.args}}" ]
  - name: pod-racing
    dag:
      tasks:
      - name: Start
        template: bash
        arguments:
          parameters: [{name: args, value: "echo \"3, 2, 1\""}]
      - name: Anakin
        dependencies: [Start]
        template: bash
        arguments:
          parameters: [{name: args, value: "echo Anakin started at: {{ tasks.Start.startedAt }}"}]
      - name: Sebulba
        dependencies: [Start]
        template: bash
        arguments:
          parameters: [{name: args, value: "echo Sebulba started at: {{ tasks.Start.startedAt }}"}]
      - name: Finish
        dependencies: [Anakin, Sebulba]
        template: bash
        arguments:
          parameters: [{name: args, value: "echo Anakin finished at: {{ tasks.Anakin.finishedAt }}, Sebulba finishd at: {{ tasks.Sebulba.finishedAt }}"}]
```

In this example you can see the DAG syntax. Dependencies are explicitly declared (like e.g. Airflow) between the different steps. In this case Start will run first, followed by Sebulba and Anakin in parallel. Finish will run last, after Anakin and Sebulba have completed.

Also note the usage of the `tasks` reference in the template variables. This is metadata passed in by Argo about the completion of previous tasks, in this case used to determine when previous containers started and finished.

Now let's see the same example but with the Steps syntax:

```yml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: dag-pod-racing-
spec:
  entrypoint: pod-racing
  templates:
  - name: bash
    inputs:
      parameters:
      - name: args
    container:
      image: busybox:latest
      command: [sh, -c]
      args: ["{{inputs.parameters.args}}" ]
  - name: pod-racing
    steps:
    - - name: Start
        template: bash
        arguments:
          parameters: [{name: args, value: "echo \"3, 2, 1\""}]
    - - name: Anakin
        template: bash
        arguments:
          parameters: [{name: args, value: "echo Anakin started at: {{ tasks.Start.startedAt }}"}]
      - name: Sebulba
        template: bash
        arguments:
          parameters: [{name: args, value: "echo Sebulba started at: {{ tasks.Start.startedAt }}"}]
    - - name: Finish
        template: bash
        arguments:
          parameters: [{name: args, value: "echo Anakin finished at: {{ tasks.Anakin.finishedAt }}, Sebulba finishd at: {{ tasks.Sebulba.finishedAt }}"}]
```

Not the single and double dashes in the steps syntax. Single dashes indicate parallel runs, double dashes indicate sequential runs. The end result is the same as the DAG syntax, Start will run first, followed by Anakin and Sebulba in parallel and ending with Finish.

To run these example execute the following make commands:

```console
make pod-racing
make pod-racing-steps
```

### Using artifacts with Argo

Argo supports passing artifacts (e.g. files) between containers in a workflow. In order to showcase this functionality, first we need to an artifact repository. Argo supports many Artifact repositories (e.g. S3, GCS, Minio). But to keep things Kubernetes native, we will stick with Minio. (For details on the configuration, check out the [artifact configuration guide](https://argoproj.github.io/argo-workflows/configure-artifact-repository)).

> Note: Minio is quite memory intensive. If you experience issues running this part of the demo, configure your Docker Daemon with more memory.

First we will install Minio:

```console
make install-minio
```

This installs Minio into the cluster. If you want to reach the Minio UI locally, you can navigate to `localhost:9000`. The access key and secret key can be retrieved using the following commands:

```console
ACCESS_KEY=$(kubectl get secret minio -o jsonpath="{.data.accesskey}" | base64 --decode) && SECRET_KEY=$(kubectl get secret minio -o jsonpath="{.data.secretkey}" | base64 --decode)
echo "Access Key: $ACCESS_KEY"
echo "Secret Key: $SECRET_KEY"
```

If you check the `04_file_io/install.sh` script there are a few things of note:

- We use a kubectl patch to set the port of the Minio container to hostPort, allowing us to access it on port 9000.
- We deploy a new version of the workflow-controller-configmap to configure the default Artifact repository used by Argo Workflows.
- We add an alias to the local deployment to the Minio client: minio-local.

First to run our file example we will upload a sample CSV to Minio:

```console
make load-csv
```

This will load the `04_file_io/csv/orders.csv` to the `csv-orders` bucket in Minio.

Now let's look at an example where we make use of artifact passing:

```yml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: artifact-passing-
spec:
  entrypoint: artifact-example
  templates:
  - name: artifact-example
    steps:
    - - name: generate-csv
        template: echo-csv
    - - name: data-engineering
        template: data-engineering
        arguments:
          artifacts:
            - name: orders-csv
              from: "{{steps.generate-csv.outputs.artifacts.orders-csv}}"
    - - name: print-output
        template: print-output
        arguments:
          artifacts:
          - name: output
            from: "{{steps.data-engineering.outputs.artifacts.out-txt}}"

  - name: echo-csv
    inputs:
      artifacts:
        - name: csv-orders
          path: /orders.csv
          s3:
            bucket: csv-orders
            key: orders.csv
            endpoint: minio:9000
            insecure: true
            accessKeySecret:
              name: minio
              key: accesskey
            secretKeySecret:
              name: minio
              key: secretkey
    container:
      image: busybox:latest
      command: [sh, -c]
      args: ["cat /orders.csv >> /tmp/orders.csv" ]
      volumeMounts:
        - mountPath: /tmp
          name: temp-volume
    volumes:
    - name: temp-volume
      emptyDir: {}
    outputs:
      artifacts:
      - name: orders-csv
        path: /tmp/orders.csv

  - name: data-engineering
    inputs:
      artifacts:
      - name: orders-csv
        path: /tmp/orders.csv
    container:
      image: busybox:latest
      command: [sh, -c]
      args: ["while read line; do echo \"line is: $line\" >> /tmp/out.txt; done < /tmp/orders.csv" ]
      volumeMounts:
        - mountPath: /tmp
          name: temp-volume
    volumes:
    - name: temp-volume
      emptyDir: {}
    outputs:
      artifacts:
      - name: out-txt
        path: /tmp/out.txt

  - name: print-output
    inputs:
      artifacts:
      - name: output
        path: /tmp/output
    container:
      image: busybox:latest
      command: [sh, -c]
      args: ["cat /tmp/output"]
      volumeMounts:
        - mountPath: /tmp
          name: temp-volume
    volumes:
    - name: temp-volume
      emptyDir: {}
```

The `echo-csv` step defines an input artifact which references the "remote" minio endpoint and the path to our loaded csv file. The `echo-csv` step also defines an output artifact, which is the location of the loaded CSV file. The `data-engineering` step takes in an input artifact and returns an output artifact. The input artifact is passed from the previous step by reference from the template variables `from: "{{steps.generate-csv.outputs.artifacts.orders-csv}}"`. The `print-output` step takes an input artifact and prints it's contents. Again the artifact is passed by reference.

> Note the volumes defined for each step. This is a consequence of not being able to use the Docker Executor, which would directly interact with the containers to load the artifacts into the container. However, the artifacts still end up in Minio, and you can see that when monitoring the Minio UI during the execution of the workflow.