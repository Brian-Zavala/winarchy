@echo off
rem Stand-in for the codex.cmd shim npm installs on Windows (tests/agent-usage.Tests.ps1).
rem Runs the fake app-server with the interpreter the test itself found, so it works on a
rem machine without the py launcher; py -3 is only the fallback.
if defined WINARCHY_TEST_PYTHON (
  "%WINARCHY_TEST_PYTHON%" "%~dp0fake_codex.py" %*
) else (
  py -3 "%~dp0fake_codex.py" %*
)
