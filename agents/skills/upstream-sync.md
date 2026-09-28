# Upstream sync

Use this when porting what the daily `upstream` pull request reports: Omarchy commits since `reviewedCommit` in `default/upstream.json`, grouped by the Winarchy area they touch.

## Steps

1. Read the pull request's report, or run it yourself: `winarchy dev upstream` (add `--since <sha>` for another starting point). Nothing is written without `--write`.
2. For each area with Winarchy files to review, read the upstream diff (the commit links), then the Winarchy files the report names. Decide per change: port it, adapt it to Windows, or skip it because Windows has no equivalent.
3. Port each change as its own commit, in the repo's usual style, with its manual chapter updated in the same commit. Mention the upstream commit in the message (`Omarchy <sha7>`).
4. A change Windows can't follow goes in the chapter's "Windows limits" note when it's user-visible, so the difference is stated rather than silent.
5. Merge the `upstream-sync` pull request last. That moves `reviewedCommit` and, on a new release, `omarchyTag`, so the next report starts after it.

## Where things map

The watch table is `$UpstreamWatch` in `lib/upstream.ps1`. When upstream adds a path the report files under _Other_, add a row there (and a case to `tests/upstream.Tests.ps1`) in the same commit as the port.

## New releases

A new Omarchy release moves `omarchyTag` in `default/config.json`, so `winarchy update` downloads its themes and backgrounds on every PC. Check the release notes for theme additions and renamed colors (`bin/omarchy-theme-color` changes land under _Theming_), and run the palette comparison in the tests against the new release when it changed.
