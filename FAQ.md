# Documenation: 

AWS Batch is a way to "spin up" AWS ECS instances on-demand in order to execute 
Docker Containers.  A simple AWS Batch environment consists of a Compute 
Environment, a Job Queue, a Job Definition and a Job.  Simply, the Compute 
Environment manages EC2/SPOT instances, the Job Queue is the entry point for 
Job requests, the Job Definition is a registered Docker Container and the Job 
is a request to do some work using a Job Definition (or Docker Container).

https://docs.aws.amazon.com/batch/latest/userguide/what-is-batch.html

Let us start with a simple example.  Using this utility:

https://gitlab.labmed.uw.edu/crosenth/aws_batch/

A simple Batch request (with some verbosity) could look like this:

```
aws_batch -v --job-queue optimal --command 'echo hello world' ubuntu-18-04
mkdir -p tmp; cd tmp; echo hello world
ubuntu-18-04 "echo hello world"
RUNNABLE
STARTING
hello world
SUCCEEDED
```

How do I understand resource allocation?

Resource allocation defines which EC2/SPOT instance will chosen to run your
Job request. Resource allocation can be defined at any point in the Batch
process with the Batch Job having the final word on how much compute resources
it needs to execute properly.  EC2 instances come in a variety of CPU and RAM
combinations: 

https://aws.amazon.com/ec2/instance-types/

Compute Environment by default will choose an EC2 instances that meets the
minimum resource requirements based on availability in a region and pricing
to satisfy the requirements defined in a Job or Job Definition.  The Batch 
minimum resource requirements are 1 cpu and 4 MB of RAM.  Given those
requirements expect to to be allocated an EC2 instance with 2 CPUs and 4-8 GB
of RAM depending on region and availability.

What if my Job requires more resources?

If a Job is expected to exceed the resource requirements defined in a Job
Definition the Job can override those minimum requirements to request a larger
EC2 instance.  Defining a higher number of CPUs and more memory will also be 
mapped to the Docker run arguments `--cpu-shares` and `--memory`:

https://docs.docker.com/config/containers/resource_constraints/

Keep in mind `--cpu-shares` will not prevent Docker containers from utilizing
every CPU available in an EC2 instance but `--memory` *will* prevent a Docker 
container from utilizing more than the requested amount.  In other words, 
expect CPU allocation to behave as a floor requirment and RAM requirement a 
ceiling requirement.

What Compute Environments, Queues and Job Definitions are available?

Using the awscli (pip install awscli):

```
aws batch describe-compute-environments > environments.txt
aws batch describe-queues > queues.txt
aws batch describe-job-definitions > job-definitions.txt
```

How do I create my own Job Definitions?

Docker containers are registered with the following command:

```
aws batch register-job-definition --cli-input-json file://jobDefinition.json
```

The jobDefinition.json file could look something like this:

```
% cat jobDefininition.json
{
    "jobDefinitionName": "myjobDefinition",
    "type": "container",
    "containerProperties": {
        "image": "ubuntu:18.04",
        "vcpus": 1,
        "memory": 1024,
        "command": [ "true" ],
        "volumes": [
            {
                "host": {
                    "sourcePath": "/home/ec2-user/miniconda"
                },
                "name": "aws-cli"
            },
        ],
				"mountPoints": [
            {
                "containerPath": "/home/ec2-user/miniconda",
                "readOnly": true,
                "sourceVolume": "aws-cli"
            },
        ],
    }
}
```

For this example the awscli is mounted from the EC2 instance into the Docker
Container to the give users the ability to move data in and out of the Docker 
Container for processing.  The awscli can also be installed to the Container
itself depending on the Docker Image and Dockerfile.

What does it mean if I get this error ... ?

How can I test my aws credentials?

How can I see files in my s3 bucket folder?

```
 aws s3 ls --human-readable --recursive s3://mybucket/folder/
```

How do I clean up my s3 bucket folder?

Use the `--recursive` command to remove an entire folder:

```
aws s3 rm --recursive s3://mybucket/folder/
```

Or if you just want to remove a single file:

```
aws s3 rm s3://mybucket/folder/remove-me.txt
```

For information on additional, useful options:

```
aws s3 rm help
```
