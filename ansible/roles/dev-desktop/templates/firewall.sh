#!/bin/bash
#
# {{ ansible_managed }}
#

cmd -A public_input_udp -p udp --dport "60000:61000" -j ACCEPT
