include:
  - gitlab.user
  - gitlab.ruby

{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{% set lib_dir = salt['pillar.get']('gitlab:lookup:lib_dir', root_dir ~ '/libraries') %}

{% set shell_dir = lib_dir ~ "/gitlab-shell" %}

{% if salt['pillar.get']('gitlab:archives:enabled', false) %}
    {% set shell_dir_content = shell_dir ~ '/' ~ salt['pillar.get']('gitlab:archives:sources:shell:content') %}
{% else %}
    {% set shell_dir_content = shell_dir %}
{% endif %}

gitlab-shell-fetcher:
{% if salt['pillar.get']('gitlab:archives:enabled', false) %}
  archive.extracted:
    - name: {{ shell_dir }}
    - source: {{ salt['pillar.get']('gitlab:archives:sources:shell:url') }}
    - source_hash: md5={{ salt['pillar.get']('gitlab:archives:sources:shell:md5') }}
    - archive_format: tar
    - if_missing: {{ shell_dir_content }}
    - keep: True
  file.directory:
    - name: {{ shell_dir }}
    - user: git
    - recurse:
      - user
{% else %}
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-shell.git
    - rev: {{ salt['pillar.get']('gitlab:shell_version') }}
    - target: {{ shell_dir }}
    - user: git
    - force: True
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home
{% endif %}

# https://gitlab.com/gitlab-org/gitlab-shell/blob/master/config.yml.example
gitlab-shell-config:
  file.managed:
    - name: {{ shell_dir_content }}/config.yml
    - source: salt://gitlab/files/gitlab-shell-config.yml
    - template: jinja
    - user: git
    - group: git
    - mode: 644
    - require:
    {% if salt['pillar.get']('gitlab:archives:enabled', false) %}
      - archive: gitlab-shell-fetcher
    {% else %}
      - git: gitlab-shell-fetcher
    {% endif %}

gitlab-shell:
  cmd.wait:
    - user: git
    - cwd: {{ shell_dir_content }}
    - name: ./bin/install
    - shell: /bin/bash
    - watch:
    {% if salt['pillar.get']('gitlab:archives:enabled', false) %}
      - archive: gitlab-shell-fetcher
    {% else %}
      - git: gitlab-shell-fetcher
    {% endif %}
    - require:
      - file: gitlab-shell-config

#gitlab-shell-chmod-bin:
#  file.directory:
#    - name: {{ shell_dir }}/bin
#    - file_mode: 0770
#    - recurse:
#      - mode

