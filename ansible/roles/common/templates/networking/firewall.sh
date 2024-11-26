#!/bin/bash
#
# {{ ansible_managed }}
#
set -euo pipefail
IFS=$'\n\t'

# Check if ip6tables is supported by the machine
if which ip6tables >/dev/null 2>&1 && /usr/sbin/ip6tables -L >/dev/null 2>&1; then
    IPv6=true
    COMMANDS=( "/usr/sbin/iptables" "/usr/sbin/ip6tables" )

    echo "Operating on the following protocols: ipv4, ipv6"
else
    IPv6=false
    COMMANDS=( "/usr/sbin/iptables" )

    echo "Operating on the following protocols: ipv4"
fi

CHAINS=( "tcp_bad" "public_input_tcp" "public_input_udp" "public_input_icmp"
         "input" "input_pre" )

LOCAL_IFACE="lo"

# Execute a command on all iptables commands
cmd() {
    for cmd in "${COMMANDS[@]}"; do
        "${cmd}" $@
    done
}

cmd4() {
    "/usr/sbin/iptables" $@
}

cmd6() {
    if "${IPv6}"; then
        "/usr/sbin/ip6tables" $@
    fi
}

# Parse arguments
only_reset=false
for arg; do
    if [[ "${arg}" == "-r" ]] || [[ "${arg}" == "--reset" ]]; then
        only_reset=true
    fi
done

# Reset the firewall
cmd -D INPUT -j input 2>/dev/null || true  # Remove firewall's input chain

# Flush chains
for chain in "${CHAINS[@]}"; do
    cmd -F "${chain}" 2>/dev/null || true
done
# Delete chains -- must be done after because of references
for chain in "${CHAINS[@]}"; do
    cmd -X "${chain}" 2>/dev/null || true
done

echo "Existing firewall configuration cleaned up"

# If you want only to reset the firewall, don't re-create rules and clear
# policies
if "${only_reset}"; then
    cmd -P INPUT ACCEPT
    cmd -P OUTPUT ACCEPT
    cmd -P FORWARD ACCEPT

    echo "Firewall successifully disabled"
    exit
fi

# Setup policies
cmd -P INPUT ACCEPT
cmd -P OUTPUT ACCEPT
cmd -P FORWARD DROP

# Create chains
for chain in "${CHAINS[@]}"; do
    cmd -N "${chain}"
done

# Setup bad tcp packets chain
cmd -A tcp_bad -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW \
        -j REJECT --reject-with tcp-reset
cmd -A tcp_bad -p tcp ! --syn -m state --state NEW -j DROP

# Setup tcp public input chain
cmd -A public_input_tcp -j tcp_bad
cmd -A public_input_tcp -p tcp --dport 22 -j ACCEPT

# Setup icmp public input chain
cmd -A public_input_icmp -j ACCEPT

# Setup input chain
cmd -A input -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
cmd -A input -i "${LOCAL_IFACE}" -j ACCEPT  # Accept localhost connections
cmd -A input -j input_pre
cmd -A input -p tcp -j public_input_tcp
cmd -A input -p udp -j public_input_udp
cmd4 -A input -p icmp -j public_input_icmp
cmd6 -A input -p ipv6-icmp -j public_input_icmp
cmd -A input -j DROP

echo "Applied basic configuration to the firewall"

# Load other config files
for file in /etc/firewall/*.sh; do
    if [[ -x "${file}" ]]; then
        echo "Loading script ${file}"
        source "${file}"
    fi
done

# Setup INPUT chain
cmd -A INPUT -j input  # Move to my input chain

echo "Firewall successifully enabled"
