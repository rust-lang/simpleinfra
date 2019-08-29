#!/bin/bash
#
# {{ ansible_managed }}
#

{% for ip in collect_metrics_from %}
cmd4 -A public_input_tcp -p tcp -s {{ ip | quote }} --dport 9100 -j ACCEPT
{% else %}
# Intentionally left blank.
{% endfor %}
