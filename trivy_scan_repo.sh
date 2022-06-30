#!/bin/bash


cmd="trivy fs --security-checks vuln,config,secret \
--exit-code 1 \
./"
(set -x; ${cmd})
