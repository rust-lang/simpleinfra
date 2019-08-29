#!/usr/bin/env python3
#
# {{ ansible_managed }}
#

import json
import os
import subprocess
import traceback

RESTIC_BIN = "/usr/local/bin/restic"
PLANS = "/etc/backup.d"
ENV = {
    "RESTIC_REPOSITORY": "{{ repository }}",
    "RESTIC_PASSWORD": """{{ password }}""",
    "HOME": "/home/local-backup",
    {% for key, value in env.items() %}
    "{{ key }}": "{{ value }}",
    {% endfor %}
}
KEEP_DAILY = "{{ keep_daily }}"
KEEP_WEEKLY = "{{ keep_weekly }}"

class BackupPlan:
    def __init__(self, path):
        with open(path) as f:
            self._manifest = json.load(f)
        self.name = self._manifest["name"]
        self.backup_path = self._manifest["path"]
        self.before = self._manifest.get("before-script", None)
        self.after = self._manifest.get("after-script", None)

    def execute(self):
        if self.before is not None:
            print("[i] Executing before script: %s" % self.name)
            subprocess.run(self.before, shell=True, check=True)

        print("[i] Executing backup: %s" % self.name)
        subprocess.run([
            RESTIC_BIN, "backup", "--tag", self.name, self.backup_path,
        ], env=ENV, check=True)

        if self.after is not None:
            print("[i] Executing after script: %s" % self.name)
            subprocess.run(self.after, shell=True, check=True)

def main():
    """Entry point for the script"""
    plans = []
    for file in os.listdir(PLANS):
        if not file.endswith(".json"):
            continue
        plans.append(BackupPlan(os.path.join(PLANS, file)))

    print("[i] Check repository status")
    res = subprocess.run([RESTIC_BIN, "snapshots"], env=ENV)
    if res.returncode != 0:
        print("[i] Initializing the repository")
        subprocess.run([RESTIC_BIN, "init"], env=ENV, check=True)

    failed = False
    for plan in plans:
        try:
            plan.execute()
        except:
            # Show the traceback and continue doing backups
            print(traceback.format_exc())
            failed = True

    print("[i] Cleaning up old backups")
    subprocess.run([
        RESTIC_BIN, "forget", "--prune",
        "--keep-daily", KEEP_DAILY, "--keep-weekly", KEEP_WEEKLY,
    ], env=ENV, check=True)

    if failed:
        exit(1)

if __name__ == "__main__":
    main()
