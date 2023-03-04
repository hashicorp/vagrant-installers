# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

$dnsserver = (,"8.8.8.8")
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE | Invoke-WmiMethod -Name SetDNSServerSearchOrder -ArgumentList (,$dnsserver)
