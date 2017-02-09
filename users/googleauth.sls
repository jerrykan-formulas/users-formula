# vim: sts=2 ts=2 sw=2 et ai
{% from "users/map.jinja" import users with context %}

users_googleauth-package:
  pkg.installed:
    - name: {{ users.googleauth_package }}
    - require:
      - file: {{ users.googleauth_dir }} 

users_{{ users.googleauth_dir }}:
  file.directory:
    - name: {{ users.googleauth_dir }}
    - user: root
    - group: {{ users.root_group }}
    - mode: 600

{% for name, user in pillar.get('users', {}).items() if user.absent is not defined or not user.absent %}
{%- if 'google_auth' in user %}
{%- for svc in user['google_auth'] %}
{%- if user.get('google_2fa', True) %}
users_googleauth-pam-{{ svc }}-{{ name }}:
  file.replace:
    - name: /etc/pam.d/{{ svc }}
    - pattern: "^@include common-auth"
    - repl: "auth       required     pam_google_authenticator.so user=root secret={{ users.googleauth_dir }}/${USER}_{{ svc }} echo_verification_code\n@include common-auth"
    - unless: grep pam_google_authenticator.so /etc/pam.d/{{ svc }}
    - backup: .bak
{%- endif %}
{%- endfor %}
{%- endif %}
{%- endfor %}
