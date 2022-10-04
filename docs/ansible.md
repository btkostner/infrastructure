# docs/ansible

Install the ansible requirements

```
ansible-galaxy install -p roles -r roles/requirements.yml
```

Then run all of the playbooks

```
ansible-playbook -i inventories/production ./playbooks/site.yml --ask-become-pass
```
