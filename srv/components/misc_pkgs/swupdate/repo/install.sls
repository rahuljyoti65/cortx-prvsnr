#
# Copyright (c) 2020 Seagate Technology LLC and/or its Affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# For any questions about this software or licensing,
# please email opensource@seagate.com or cortx-questions@seagate.com.
#

{% macro repo_added(release, source, source_type) %}

    {% from './iso/mount.sls' import repo_mounted with context %}

    {% if source_type == 'iso' %}

        {% set iso_path = source + '.iso' %}

copy_repo_iso_{{ release }}:
  file.managed:
    - name: {{ iso_path }}
    - source: salt://misc_pkgs/swupdate/repo/files/{{ release }}.iso
    - makedirs: True
    - require_in:
      - sw_update_repo_iso_mounted_{{ release }}
      - sw_update_repo_added_{{ release }}


{{ repo_mounted(release, iso_path, source) }}

    {% elif source_type == 'dir' %}


copy_repo_dir_{{ release }}:
  file.recurse:
    - name: {{ source }}
    - source: salt://misc_pkgs/swupdate/repo/files/{{ release }}
    - require_in:
      - sw_update_repo_added_{{ release }}


    {% endif %}


sw_update_repo_added_{{ release }}:
  pkgrepo.managed:
    - name: sw_update_{{ release }}
    - humanname: Cortx Update repo {{ release }}
    {% if source_type == 'url' %}
    - baseurl: {{ source }}
    {% else %}
    - baseurl: file://{{ source }}
    {% endif %}
    - gpgcheck: 0
    {% if source_type == 'iso' %}
    - require:
      - sw_update_repo_iso_mounted_{{ release }}
    {% endif %}


sw_update_repo_metadata_cleaned_{{ release }}:
  cmd.run:
    - name: yum --disablerepo="*" --enablerepo="sw_update_{{ release }}" clean metadata
    - require:
      - sw_update_repo_added_{{ release }}

{% endmacro %}