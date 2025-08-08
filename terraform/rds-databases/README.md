# RDS databases

This module creates a `shared` RDS instance that contains three databases:

- `triagebot`
- `rustc_perf`

You can access the DB instance using [bastion].

To run `terraform` commands, use the following command
to port-forward the bastion host:

```sh
ssh -L localhost:57467:shared.<id>.us-west-1.rds.amazonaws.com:5432 <user>@bastion.infra.rust-lang.org
```

Where `57467` can be any unused port on your local machine.

Then you can connect to the database using `psql`:

```sh
psql postgres://<username>:<password>@localhost:57467/<database>
```

You can find the full endpoint (including `<id>`) in the
AWS console.

[bastion]: https://github.com/rust-lang/infra-team/tree/master/service-catalog/bastion
