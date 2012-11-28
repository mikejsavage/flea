#! /bin/sh

echo $* | curl -H "Content-Type: application/json" -d @- 0.0.0.0:8080
