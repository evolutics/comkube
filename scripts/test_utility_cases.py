#!/usr/bin/env python3

import difflib
import json
import re
import subprocess
import sys
import typing


def main() -> int:
    test_command = sys.argv[1:]
    test_cases = json.load(sys.stdin)

    exit_status = 0

    for summary, test_case in test_cases.items():
        error = _test(
            command=test_command,
            input_=test_case.get("input"),
            expected=test_case.get("expected"),
        )

        if error:
            print(f"❌ Fail: {summary}:\n{error}")
            exit_status = 1
        else:
            print(f"✅ Pass: {summary}")

    return exit_status


def _test(command: list[str], input_: dict | None, expected: dict | None) -> str | None:
    if input_ is None:
        stdin = None
    else:
        stdin = json.dumps(input_["json"])

    # pylint: disable-next=subprocess-run-check
    actual = subprocess.run(command, capture_output=True, input=stdin, text=True)

    expected_exit_status = expected.get("exit_status", 0)
    if actual.returncode != expected_exit_status:
        return f"Exit status is {actual.returncode}, expected {expected_exit_status}."

    if expected_json := expected.get("stdout_json"):
        try:
            actual_json = json.loads(actual.stdout)
        except json.JSONDecodeError as error:
            return str(error)
        if actual_json != expected_json:
            diff = _diff(
                actual=_pretty_json(actual_json), expected=_pretty_json(expected_json)
            )
            return f"Diff in stdout JSON:\n{diff}"

    if expected_regex := expected.get("stderr_regex"):
        if not re.fullmatch(expected_regex, actual.stderr, flags=re.DOTALL):
            return f"Stderr does not match regex {expected_regex!r}:\n{actual.stderr}"

    return None


def _diff(actual: str, expected: str) -> str:
    return "\n".join(
        difflib.unified_diff(
            actual.splitlines(),
            expected.splitlines(),
            fromfile="Actual",
            tofile="Expected",
            lineterm="",
        )
    )


def _pretty_json(object_: typing.Any) -> str:
    json.dumps(object_, sort_keys=True, indent=4)


if __name__ == "__main__":
    sys.exit(main())
