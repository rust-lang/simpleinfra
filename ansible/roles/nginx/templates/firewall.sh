#!/bin/bash
#
# {{ ansible_managed }}
#

cmd -A public_input_tcp -p tcp --dport 80 -j ACCEPT
cmd -A public_input_tcp -p tcp --dport 443 -j ACCEPT
