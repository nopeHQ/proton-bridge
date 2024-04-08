#!/usr/bin/env bash

# Fix bug https://github.com/mattn/go-sqlite3/pull/1177 before make stage


sed -i '/replace (/a github.com/mattn/go-sqlite3 v1.14.17 => github.com/mattn/go-sqlite3 v1.14.20' /build/proton-bridge/go.mod

cd /build/proton-bridge/ || exit
go mod tidy