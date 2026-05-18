#!/usr/bin/env python3
"""
Custom Ansible Dynamic Inventory Script
Fulfills ex374 exam requirements by providing a 'web' host group.
"""

import sys
import argparse
import json

class FreeLDAPInventory(object):
    def __init__(self):
        self.inventory = {}
        self.read_cli_args()

        # Handle the standard execution flags required by Ansible
        if self.args.list:
            self.inventory = self.get_inventory_data()
        elif self.args.host:
            # Group variables are passed under '_meta', so we return empty hostvars here
            self.inventory = self.empty_inventory()
        else:
            self.inventory = self.empty_inventory()

        print(json.dumps(self.inventory, indent=2))

    def get_inventory_data(self):
        """
        Defines and returns the core structure.
        Ensures the 'web' host group is present for your target hosts.
        """
        return {
            "all": {
                "children": ["web"]
            },
            "web": {
                # Replace these placeholder names/IPs with your exact lab host targets
                "hosts": [
                    "webserver01.mainak.com",
                    "webserver02.mainak.com"
                ],
                "vars": {
                    "ansible_connection": "ssh"
                }
            },
            "_meta": {
                "hostvars": {
                    "webserver01.mainak.com": {
                        "ansible_host": "192.168.1.51"
                    },
                    "webserver02.mainak.com": {
                        "ansible_host": "192.168.1.52"
                    }
                }
            }
        }

    def empty_inventory(self):
        return {"_meta": {"hostvars": {}}}

    def read_cli_args(self):
        parser = argparse.ArgumentParser()
        parser.add_argument('--list', action='store_true', help='List all active groups and hosts')
        parser.add_argument('--host', action='store', help='List specific host variables')
        self.args = parser.parse_args()

if __name__ == '__main__':
    FreeLDAPInventory()
