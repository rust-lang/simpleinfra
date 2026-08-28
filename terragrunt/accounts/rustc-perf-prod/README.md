# rustc-perf production AWS account

This account contains one Graviton 5 collector for rustc-perf. It is an
`m9g.metal-48xl` bare-metal instance with 192 vCPUs and 768 GiB of memory in
`us-east-2`. It gives the collector direct access to the physical Graviton 5
server and its performance monitoring unit.

Operators connect to the machine over SSH.
Its Elastic IPv4 address stays stable across instance
stop/start cycles. The instance also has a stable public IPv6 address.
