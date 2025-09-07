#!/usr/bin/env python3

import subprocess
import sys


def main() -> int:
    try:
        k8s_manifests = subprocess.run(
            # TODO: Process CLI arguments properly.
            ["kompose"] + sys.argv[1:] + ["convert", "--stdout"],
            check=True,
            stdout=subprocess.PIPE,
        ).stdout
    except subprocess.CalledProcessError as error:
        return abs(error.returncode)

    try:
        # TODO: Prune using kubectl ApplySet.
        subprocess.run(
            ["kubectl", "apply", "--filename", "-"], check=True, input=k8s_manifests
        )
    except subprocess.CalledProcessError as error:
        return abs(error.returncode)

    return 0


if __name__ == "__main__":
    sys.exit(main())
