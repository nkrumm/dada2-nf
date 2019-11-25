AWS Batch is a way to execute Docker Containers using AWS ECS instances 
on-demand.  A simple AWS Batch environment consists of a Compute 
Environment, a Job Queue, a Job Definition and a Job.  Simply, a Compute 
Environment manages EC2/SPOT instances, the Job Definition is a 
registered Docker Container, a Job request is some work instruction
pointing toa Job Definition (Docker Container) and a Job Queue acts a gateway
between Job requests and the Compute Environment.

https://docs.aws.amazon.com/batch/latest/userguide/what-is-batch.html

Starting with a simple example using this utility:

https://gitlab.labmed.uw.edu/crosenth/aws_batch/

A simple Batch request (with some verbosity) looks like this:

```
aws_batch -v --job-queue optimal --command 'echo hello world' ubuntu-18-04
mkdir -p tmp; cd tmp; echo hello world
ubuntu-18-04 "echo hello world"
RUNNABLE
STARTING
hello world
SUCCEEDED
```

### How do I understand resource allocation?

Resource allocation defines which EC2/SPOT instance will be chosen to run your
Job request. Resource allocation can be defined at any point in the Batch
process with the Batch Job having the final word on how much compute resources
it needs to execute properly.  EC2 instances come in a variety of CPU and RAM
combinations: 

https://aws.amazon.com/ec2/instance-types/

Compute Environment by default will choose an EC2 instances that meets the
minimum resource requirements based on availability in a region and pricing
to satisfy the requirements defined in a Job or Job Definition.  The Batch 
minimum resource requirements are 1 cpu and 4 MB of RAM.  

### Specifying job resources

If a Job is expected to exceed the resource requirements defined in a Job
Definition the Job can override the Job Definition.
Defining a higher number of CPUs and more memory will also be 
mapped to the Docker run arguments `--cpu-shares` and `--memory`:

https://docs.docker.com/config/containers/resource_constraints/

Keep in mind `--cpu-shares` will not prevent Docker containers from utilizing
every CPU available in an EC2 instance but `--memory` *will* prevent a Docker 
container from utilizing more than the requested amount.  Think of CPU 
allocation as a floor requirment and the RAM requirement as a ceiling 
requirement.

What Compute Environments, Queues and Job Definitions are available?

Using the awscli (pip install awscli):

```
aws batch describe-compute-environments
...
aws batch describe-queues
...
aws batch describe-job-definitions
...
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
Container to the give users the ability to move data in and out of the
Container for processing.  The awscli can also be installed to the Container
itself from Docker Image and Dockerfile.

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
