#
# Copyright (c) 2020 Seagate Technology LLC and/or its Affiliates
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# For any questions about this software or licensing,
# please email opensource@seagate.com or cortx-questions@seagate.com.
#

# Ensure ssh works when the firwall servcie starts for the next time
Reset default zone:
  firewalld.present:
    - name: trusted
    - default: True
    - prune_ports: False
    - prune_services: False
    - prune_interfaces: False

{% if 'mgmt0' in grains['ip4_interfaces'] and grains['ip4_interfaces']['mgmt0'] -%}
  {% set mgmt_ifs = ['mgmt0'] %}
{% else -%}
  {% set mgmt_ifs = pillar['cluster'][grains['id']]['network']['mgmt']['interfaces'] %}
{% endif -%}
Remove public manaement interfaces:
  cmd.run:
    - name: |
        {% for interface in mgmt_ifs -%}
        firewall-cmd --remove-interface={{ interface }} --zone=public --permanent
        {% endfor %}

{% if ('data0' in grains['ip4_interfaces']) and (grains['ip4_interfaces']['data0']) %}
Remove public data interfaces:
  cmd.run:
    - name: firewall-cmd --remove-interface=data0 --zone=public-data-zone --permanent
    - onlyif: firewall-cmd --get-zones | grep public-data-zone
{% else %}
Remove public data interfaces:
  cmd.run:
    - name: |
        {% for interface in pillar['cluster'][grains['id']]['network']['data']['public_interfaces'] -%}
        firewall-cmd --remove-interface={{ interface }} --zone=public-data-zone --permanent
        {% endfor %}
    - onlyif: firewall-cmd --get-zones | grep public-data-zone

Remove private data interfaces:
  cmd.run:
    - name: |
        {% for interface in pillar['cluster'][grains['id']]['network']['data']['private_interfaces'] -%}
        firewall-cmd --remove-interface={{ interface }} --zone=trusted --permanent
        {% endfor %}
    - onlyif: firewall-cmd --get-zones | grep trusted
{% endif %}

Remove public-data-zone:
  cmd.run:
    - name: firewall-cmd --permanent --delete-zone=public-data-zone
    - onlyif: firewall-cmd --get-zones | grep public-data-zone
    - require:
      - Reset default zone

Reload firewall:
  cmd.run:
    - name: firewall-cmd --reload

Delete firewall checkpoint flag:
  file.absent:
    - name: /opt/seagate/cortx/provisioner/generated_configs/{{ grains['id'] }}.firewall
