# Dada2 Nextflow pipeline

Using the minimal config settings below run the pipeline

```
nexflow run main.nf
```

Nextflow will use the `standard` profile by default.

## config

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
