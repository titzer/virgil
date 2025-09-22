#!/usr/bin/env bash

echo $(ls */*.v3 | sort | cut -d/ -f1 | uniq)
