#!/usr/bin/env python3
import os
import subprocess

base_path = "/ansible_platform"
sub_dirs = ["set1_sysctl", "set1_daemon", "set1_gates", "set1_tuning", "set1_loops", "set1_variable_template", "set1_local_invocation"]

for folder in sub_dirs:
    target = os.path.join(base_path, folder)
    os.makedirs(target, exist_ok=True)
    subprocess.run(["git", "init"], cwd=target, capture_output=True)
    
    if folder == "set1_sysctl":
        with open(os.path.join(target, "user_list.yaml"), "w") as f:
            f.write("---\n# Existing file\n")
        with open(os.path.join(target, "inventory"), "w") as f:
            f.write("\n")
            
    elif folder == "set1_daemon":
        with open(os.path.join(target, "alias.yml"), "w") as f:
            f.write("---\n- name: Set1 Daemon Playbook\n  hosts: all\n  tasks:\n    - name: Copy tracking template\n      ansible.builtin.copy:\n        content: 'Config version 1.0'\n        dest: /etc/sysctl.d/99-ops.conf\n")
            
    elif folder == "set1_gates":
        with open(os.path.join(target, "content.yaml"), "w") as f:
            f.write("---\n- name: Flow Control\n  hosts: all\n  tasks:\n    - name: Setup block one\n      ansible.builtin.copy:\n        content: 'Hello from Init'\n        dest: /var/www/html/index.html\n    - name: Setup block two\n      ansible.builtin.copy:\n        content: 'Hello from Final'\n        dest: /var/www/html/index.html\n")

    elif folder == "set1_variable_template":
        with open(os.path.join(target, "inventory.py"), "w") as f:
            f.write("#!/usr/bin/env python3\nimport json\nprint(json.dumps({'all': {'hosts': ['localhost']}, '_meta': {'hostvars': {}}}))\n")
        os.chmod(os.path.join(target, "inventory.py"), 0o755)

print("[SUCCESS] Set 1 Practice Workspace Generated.")
