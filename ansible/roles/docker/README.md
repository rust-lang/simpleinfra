# `docker` role

This role install and configures the Docker daemon on the instance, creates a
timer to periodically pull new Docker images from ECR and manages the
configured containers with systemd.

To pull the images from ECR the timer needs to assume an AWS IAM role with
permissions to do so: if the machine is running on EC2 the role is
automatically picked up, otherwise both the role ARN and a set of credentials
able to assume it need to be provided.


## Operating

This role creates a new systemd service for each container it manages, named
`container-<name>.service`. The usual systemctl commands (`status`, `start`,
`stop`, `restart`) properly work as if the container was a native systemd
service. Logs are also forwarded to the journal, and can be inspected with
`journalctl`.

The images are pulled every time the machine boots, and also at configurable
intervals thanks to a timer configured by this role. Every time the timer pulls
a new image the related container is restarted, without impacting the other
running containers.

## Configuration

```yaml
- role: docker

  images:
    # AWS region where the ECR repositories are located.
    region: us-west-1
    # systemd timespan of the interval between image updates.
    # The interval will be used to start a timer that pulls all the configured
    # images and restarts the container if needed.
    # See `man 7 systemd.time` for the timespan syntax.
    updated_every: 5min
    # AWS credentials to assume the configured IAM roles. This section only
    # needs to be added if the instance is running outside EC2. Otherwise it
    # can be set to `null`.
    aws_credentials:
      # ARN of the IAM role the updater timer should assume to be able to pull
      # from the ECR repository.
      role_arn: arn:aws:iam::123456789:role/foobar
      # AWS credentials allowed to sts:AssumeRole the role configured above.
      access_key_id: AAAAAAAAA
      secret_access_key: AAAAAAAAA

  containers:
    # Definition of a container hosted on the instance.
    # The name of the container has to be replaced with a unique one.
    container-name:
      # Name of the image that will be used to start the container.
      image: 123456789.dkr.ecr.us-west-1.amazonaws.com/image-repository:latest
      # Command line arguments to pass to the container.
      exec: command subcommand
      # Host directories to mount inside the container, with write permissions.
      mounts:
        # "host-directory": "container-directory"
        "/var/lib/container-data": "/data"
      # Environment variables to pass to the container
      env:
        FOO: bar
      # Ports to expose from the container to the host system.
      expose:
        # host-port: container-port
        8001: 80
```
