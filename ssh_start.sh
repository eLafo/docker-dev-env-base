#!/bin/bash
printenv >> ~/.profile
/home/dev/ssh_key_adder.rb
sudo /usr/sbin/sshd -D
