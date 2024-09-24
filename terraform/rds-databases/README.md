# RDS databases

This module creates a `shared` RDS instance that contains three databases:

- `discord-mods-bot`
- `triagebot`
- `rustc_perf`

You can access the DB instance using [bastion].

To run `terraform` commands, use the following command
to port-forward the bastion host:

```sh
ssh -L localhost:57467:shared.<id>.us-west-1.rds.amazonaws.com:5432 bastion.infra.rust-lang.org
```

You can find the full endpoint (including `<id>`) in the
AWS console.

[bastion]: https://github.com/rust-lang/infra-team/tree/master/service-catalog/bastion
