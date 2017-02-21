#!/usr/bin/with-contenv bash

# render configuration files
/usr/local/bin/confd -onetime -backend env &>/dev/null
