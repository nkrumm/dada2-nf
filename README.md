# Dada2 Nextflow pipeline

## Local execution quickstart for the truly impatient

Install Docker and make sure that the Docker daemon is running.

Install the nextflow binary in this directory

```
wget -qO- https://get.nextflow.io | bash
```

Using the minimal config settings below run the pipeline

```
./nextflow run main.nf
```

## Execution on AWS Batch

A configuration file for AWS Batch execution will look something like this:

```
profiles{
    resume = true
    cloud {
        aws {
            batch {
                cliPath = '/home/ec2-user/miniconda/bin/aws'
                jobRole = 'arn:aws:iam::::'
                volumes = ['/docker_scratch:/tmp:rw']
            }
            region = 'us-west-2'
        }
        process {
            executor = 'awsbatch'
            queue = 'mixed'
        }
    }
    standard {
        docker {
            enabled = true
        }
        params {
            output = 'output'
        }
        process {
            executor = 'local'
        }
    }
}
```

TODO: some high-level guidance on how to learn how to set up Batch.

## Development tips

- force local execution without docker for a specific task by
  including ``container null`` within the process definition
