# Dev Desktops GCP

## How to configure

- Add the public IP address of the machine to `ansible/envs/prod/hosts`
- Download the buildbot private SSH key from 1Password
- `chmod 600 <path-to-buildbot-west-slave-key.pem>`
- `export ANSIBLE_PRIVATE_KEY_FILE=<path-to-buildbot-west-slave-key.pem>`
- `cd ansible && ./apply prod dev-desktop -u ubuntu`
