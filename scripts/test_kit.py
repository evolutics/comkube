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
    test_count = len(test_cases)

    test_order = list(range(test_count))
    random.shuffle(test_order)

    test_errors = [None] * test_count
    for index in test_order:
        test_case = test_cases[index][1]
        test_errors[index] = _test(**test_case)

    for index, error in enumerate(test_errors):
        name = test_cases[index][0]
        if error:
            print(f"❌ Fail: {name}:\n{error}")
        else:
            print(f"✅ Pass: {name}")

    if any(test_errors):
        return 1
    return 0


def _get_test_cases(test_suite_paths: list[str]) -> list[dict]:
    test_cases = []

    for test_suite_path in test_suite_paths:
        with open(test_suite_path, "rb") as test_suite:
            test_suite = json.load(test_suite)
        metadata = test_suite.pop("")

        for summary, test_case in test_suite.items():
            test_cases.append(
                (
                    f"{test_suite_path}: {summary}",
                    {
                        "command": metadata["command"],
                        "expected": test_case.get("expected"),
                        "input_": test_case.get("input"),
                        "working_folder": pathlib.Path(test_suite_path).parent,
                    },
                )
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
    return json.dumps(object_, sort_keys=True, indent=4)


if __name__ == "__main__":
    sys.exit(main())
