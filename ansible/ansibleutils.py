#!/usr/bin/env python3

# Utilities for creating the Ansible environment we use.

import subprocess
import pathlib
import sys
import shutil

BASE_PATH = pathlib.Path(__file__).resolve().parent
VENV_PATH = BASE_PATH / ".venv"

# Ansible changes a lot between releases and deprecates a lot of stuff each of
# them. Using a pinned ansible identical between all team members should
# reduce the churn.
def install_ansible(venv_path = VENV_PATH):
    requirements = BASE_PATH / "requirements.txt"
    venv_requirements = venv_path / "installed-requirements.txt"

    # Avoid installing ansible in the virtualenv multiple times
    if venv_requirements.exists() and \
       venv_requirements.read_bytes() == requirements.read_bytes():
        return

    print("creating a new virtual environment and install ansible in it...")
    shutil.rmtree(venv_path, ignore_errors=True)
    subprocess.run([sys.executable, "-m", "venv", str(venv_path)], check=True)
    subprocess.run([
        str(venv_path / "bin" / "pip"), "install", "-r", str(requirements),
    ], check=True)
    shutil.copy(str(requirements), str(venv_requirements))

def create_workspace(dir, env, playbook):
    env_dir = BASE_PATH / "envs" / env
    # Create a temporary directory merging together the chosen
    # environment, the chosen playbook and the shared files.
    (dir / "play").mkdir()
    (dir / "play" / "roles").symlink_to(BASE_PATH / "roles")
    (dir / "play" / "group_vars").symlink_to(BASE_PATH / "group_vars")
    (dir / "play" / "playbook.yml").symlink_to(
        BASE_PATH / "playbooks" / (playbook + ".yml")
    )
    (dir / "env").symlink_to(env_dir)
    (dir / "ansible.cfg").symlink_to(BASE_PATH / "ansible.cfg")
