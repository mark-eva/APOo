#!/bin/bash
cd /oracle/APO/logs
sqlplus /nolog @mount_standby_result.sql
