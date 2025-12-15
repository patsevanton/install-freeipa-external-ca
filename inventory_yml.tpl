all:
  children:
    ipaserver:
      hosts:
        "${hostname}":
          ansible_host: "${freeipa_public_ip}"
  vars:
    ansible_user:  ${ssh_user}
    ipaadmin_password: ADMPassword1
    ipadm_password: ADMPassword1
    ipaserver_no_host_dns: true
    ipaserver_ip_addresses:
      - '{{ ansible_default_ipv4.address|default(ansible_all_ipv4_addresses[0]) }}'
    ipaserver_domain: apatsev.corp
    ipaserver_realm: APATSEV.CORP
    ipaserver_hostname: ipa.apatsev.corp
    ipaserver_setup_dns: true
    ipaserver_forwarders:
      - 8.8.8.8
