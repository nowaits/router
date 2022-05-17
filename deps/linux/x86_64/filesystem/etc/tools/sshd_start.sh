#!/bin/sh

[ -f /etc/ssh/id_rsa ] || ssh-keygen -f /etc/ssh/id_rsa -N "" -t rsa > /dev/null

nohup /sbin/sshd -f /etc/ssh/sshd_config > /dev/null 2>&1 &