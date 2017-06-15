#!/bin/bash
printenv > ~/.ssh/environment
/home/dev/ssh_key_adder.rb
sudo /usr/sbin/sshd -D
