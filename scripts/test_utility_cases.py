#!/usr/bin/env python3

import difflib
import json
import pathlib
import random
import re
import subprocess
import sys
import typing


def main() -> int:
    test_cases = _get_test_cases(sys.argv[1:])
    random.shuffle(test_cases)

    exit_status = 0

    for test_case in test_cases:
        name = test_case.pop("name")
        error = _test(**test_case)
        if error:
            print(f"❌ Fail: {name}:\n{error}")
            exit_status = 1
        else:
            print(f"✅ Pass: {name}")

    return exit_status


def _get_test_cases(test_suite_paths: list[str]) -> list[dict]:
    test_cases = []

    for test_suite_path in test_suite_paths:
        with open(test_suite_path, "rb") as test_suite:
            test_suite = json.load(test_suite)
        metadata = test_suite.pop("")

        for summary, test_case in test_suite.items():
            test_cases.append(
                {
                    "name": f"{test_suite_path}: {summary}",
                    "command": metadata["command"],
                    "expected": test_case.get("expected"),
                    "input_": test_case.get("input"),
                    "working_folder": pathlib.Path(test_suite_path).parent,
                }
            )

    return test_cases


def _test(
    command: list[str],
    expected: dict | None,
    input_: dict | None,
    working_folder: pathlib.Path,
) -> str | None:
    if input_ is None:
        stdin = None
    else:
        stdin = json.dumps(input_["json"])

    # pylint: disable-next=subprocess-run-check
    actual = subprocess.run(
        command, capture_output=True, cwd=working_folder, input=stdin, text=True
    )

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
