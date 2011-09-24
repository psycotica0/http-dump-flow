#!/bin/sh

# You give this script the request files you want and it forms the calls for you
# Useful for if you want to do ./read-flows.sh 192* and have it just do everything.
# It assumes the tcpflow method of naming

while [ -n "$1" ]; do
	data_dir="$(dirname "$1")"
	request_file="$(basename "$1")"
	response_file="$(echo "$request_file" | cut -d '-' -f2)-$(echo "$request_file" | cut -d '-' -f1)"
	# This dirname thing is a total hack...
	"$(dirname "$0")"/http-persistent-read.rb "$data_dir/$request_file" "$data_dir/$response_file"
	shift
done
