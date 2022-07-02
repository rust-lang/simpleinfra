#!/bin/bash
#
# {{ ansible_managed }}
#

{% set container = containers[item] -%}
{% set expose = container.expose|default({}) %}
{% for host, inside in expose.items() %}
cmd4 -A public_input_tcp -p tcp --dport {{ host }} -j ACCEPT
{% else %}
# Intentionally left blank.
{% endfor %}
