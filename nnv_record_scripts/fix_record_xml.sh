#!/bin/bash

var="<?xml version=\"1.0\"?>"
for x in $(cat $1); do
  /bin/sed -i -e "1s/.*/$var/" $x 
done
