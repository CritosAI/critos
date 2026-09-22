# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# CritOS installer (Windows) - prepares the MACHINE. Run once per machine, from this checkout:
#     powershell -ExecutionPolicy Bypass -File .\install.ps1
#
# It does NOT install CritOS into a project: that is /crit-scaffold-project, run inside the
# target repo. Delivery is hybrid: the machine provides the TOOLCHAIN (shared from this
# checkout, so keep the folder where it is), each project PINS its own copy of the contracts.
#
#   -ClaudeHome <dir>   install into another folder instead of ~/.claude (a sandbox, for tests)
#   -Uninstall          remove everything this installer manages, and nothing else
#
# What it manages, and nothing beyond it:
#   <ClaudeHome>\skills\crit-*     one junction per skill (the folder itself stays yours)
#   <ClaudeHome>\hooks\critos      a junction to this checkout's hooks
#   <ClaudeHome>\settings.json     ONE PreToolUse entry, the guard (a backup is written first)
#   <ClaudeHome>\CLAUDE.md         ONE block, between the CritOS markers
#
# Idempotent: what is already correct is left untouched. Restart Claude Code afterward.
# ASCII-only on purpose: Windows PowerShell 5.1 reads .ps1 as ANSI, so non-ASCII breaks parsing.

param(
    [string]$ClaudeHome = (Join-Path $env:USERPROFILE ".claude"),
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$repo      = $PSScriptRoot
$isDefault = ($ClaudeHome.TrimEnd("\") -eq (Join-Path $env:USERPROFILE ".claude").TrimEnd("\"))
$utf8      = New-Object System.Text.UTF8Encoding($false)   # no BOM: these files are read by other tools

$skillsSrc = Join-Path $repo "skills"
$hooksSrc  = Join-Path $repo "hooks"
$skillsDst = Join-Path $ClaudeHome "skills"
$hooksDst  = Join-Path $ClaudeHome "hooks"
$hookLink  = Join-Path $hooksDst "critos"
$guardName = "guard-user-driven-actions.sh"
if ($isDefault) { $hookCmd = "bash ~/.claude/hooks/critos/" + $guardName }
else            { $hookCmd = 'bash "' + ((Join-Path $hookLink $guardName) -replace "\\", "/") + '"' }

$beginTag = "<!-- BEGIN CritOS (managed) -->"
$endTag   = "<!-- END CritOS (managed) -->"

function Test-Junction($path) {
    if (-not (Test-Path $path)) { return $false }
    return ((Get-Item $path -Force).LinkType -eq "Junction")
}

function Remove-Junction($path) {
    # cmd rmdir removes the LINK and never follows it to the target.
    cmd /c rmdir "$path" | Out-Null
    return (-not (Test-Path $path))
}

function Set-Junction($link, $target, $label) {
    if (Test-Path $link) {
        if (-not (Test-Junction $link)) {
            Write-Warning ("  " + $label + " exists and is NOT a junction - left untouched (move it aside first).")
            return
        }
        $current = (Get-Item $link -Force).Target | Select-Object -First 1
        if ($current -and ($current.TrimEnd("\") -eq $target.TrimEnd("\"))) {
            Write-Host ("  ok        " + $label + "  (already correct)")
            return
        }
        if (-not (Remove-Junction $link)) {
            Write-Warning ("  could not remove the existing junction " + $label + " - left untouched.")
            return
        }
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host ("  junction  " + $label)
}

function Assert-RealFolder($path, $label) {
    # A whole-folder junction here would put everything anyone writes into it inside this checkout.
    if (Test-Junction $path) {
        throw ($label + " is a JUNCTION, not a folder. Remove the link (cmd /c rmdir `"" + $path + "`") and run the installer again.")
    }
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function Read-Settings($path) {
    if (Test-Path $path) {
        $raw = Get-Content $path -Raw -Encoding UTF8
        if ($raw -and $raw.Trim()) { return ($raw | ConvertFrom-Json) }
    }
    return (New-Object PSObject)
}

function Get-PreToolUse($settings) {
    if (-not ($settings.PSObject.Properties.Name -contains "hooks")) { return @() }
    if (-not ($settings.hooks.PSObject.Properties.Name -contains "PreToolUse")) { return @() }
    return @($settings.hooks.PreToolUse | Where-Object { $_ })
}

function Test-GuardEntry($entry) {
    foreach ($h in @($entry.hooks)) { if ($h -and ($h.command -eq $hookCmd)) { return $true } }
    return $false
}

function Save-Settings($path, $settings) {
    if (Test-Path $path) { Copy-Item $path ($path + ".bak-critos") -Force }
    [System.IO.File]::WriteAllText($path, ($settings | ConvertTo-Json -Depth 32), $utf8)
}

# --- which revision is being installed -------------------------------------------------------
# Through cmd: in PowerShell 5.1 a native command writing to stderr is a terminating error under
# ErrorActionPreference Stop, and "no tag here" is an answer, not a failure.
$rev = (cmd /c ('git -C "' + $repo + '" describe --tags --always --dirty 2>nul'))
$tag = (cmd /c ('git -C "' + $repo + '" describe --tags --exact-match 2>nul'))
Write-Host ("CritOS checkout: " + $repo)
if ($tag) { Write-Host ("  release   " + $tag) }
else {
    Write-Host ("  revision  " + $rev)
    Write-Warning "  this checkout is NOT at a release tag: you are installing an unreleased revision (fine for development and pilots; a project should run a release)."
}
Write-Host ""

$settingsPath = Join-Path $ClaudeHome "settings.json"
$claudeMd     = Join-Path $ClaudeHome "CLAUDE.md"

if ($Uninstall) {
    if (Test-Path $skillsDst) {
        foreach ($d in (Get-ChildItem $skillsDst -Force | Where-Object { $_.Name -like "crit-*" })) {
            if ((Test-Junction $d.FullName) -and (Remove-Junction $d.FullName)) { Write-Host ("  removed   skills\" + $d.Name) }
        }
    }
    if ((Test-Junction $hookLink) -and (Remove-Junction $hookLink)) { Write-Host "  removed   hooks\critos" }
    if (Test-Path $settingsPath) {
        $s   = Read-Settings $settingsPath
        # @(...) at the call site: PowerShell unwraps a one-element array returned by a function.
        $pre = @(Get-PreToolUse $s)
        $kept = @($pre | Where-Object { -not (Test-GuardEntry $_) })
        if ($kept.Count -ne $pre.Count) {
            $s.hooks | Add-Member -Force -NotePropertyName PreToolUse -NotePropertyValue $kept
            Save-Settings $settingsPath $s
            Write-Host "  removed   the guard entry from settings.json (backup: settings.json.bak-critos)"
        }
    }
    if (Test-Path $claudeMd) {
        $cur = Get-Content $claudeMd -Raw -Encoding UTF8
        $bi = $cur.IndexOf($beginTag); $ei = $cur.IndexOf($endTag)
        if ($bi -ge 0 -and $ei -gt $bi) {
            $new = ($cur.Substring(0, $bi).TrimEnd() + "`r`n" + $cur.Substring($ei + $endTag.Length).TrimStart()).Trim() + "`r`n"
            [System.IO.File]::WriteAllText($claudeMd, $new, $utf8)
            Write-Host "  removed   the CritOS block from CLAUDE.md"
        }
    }
    Write-Host ""
    Write-Host "CritOS removed from this machine. Projects keep their pinned contracts; their controls are gone."
    return
}

New-Item -ItemType Directory -Force -Path $ClaudeHome | Out-Null

# --- skills: one junction per skill ----------------------------------------------------------
Assert-RealFolder $skillsDst "skills"
$shipped = @(Get-ChildItem $skillsSrc -Directory | Where-Object { $_.Name -like "crit-*" })
foreach ($s in ($shipped | Sort-Object Name)) {
    Set-Junction (Join-Path $skillsDst $s.Name) $s.FullName ("skills\" + $s.Name)
}
# A skill this checkout no longer ships leaves a junction pointing at nothing: remove it.
foreach ($d in (Get-ChildItem $skillsDst -Force | Where-Object { $_.Name -like "crit-*" })) {
    if ((Test-Junction $d.FullName) -and -not ($shipped.Name -contains $d.Name)) {
        if (Remove-Junction $d.FullName) { Write-Host ("  removed   skills\" + $d.Name + "  (no longer shipped)") }
    }
}

# --- hooks: one junction, in a folder of its own ---------------------------------------------
Assert-RealFolder $hooksDst "hooks"
Set-Junction $hookLink $hooksSrc "hooks\critos"

# --- settings.json: register the guard. A guard that is installed and not registered guards
# nothing, and looks exactly like one that does.
$s   = Read-Settings $settingsPath
$pre = @(Get-PreToolUse $s)
if (@($pre | Where-Object { Test-GuardEntry $_ }).Count -gt 0) {
    Write-Host "  ok        settings.json (the guard is registered)"
} else {
    $hook  = New-Object PSObject -Property ([ordered]@{ type = "command"; command = $hookCmd; timeout = 10; statusMessage = "CritOS guard: checking user-driven actions..." })
    $entry = New-Object PSObject -Property ([ordered]@{ matcher = "Bash|PowerShell"; hooks = @($hook) })
    if (-not ($s.PSObject.Properties.Name -contains "hooks")) { $s | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject) }
    $all = New-Object System.Collections.ArrayList
    foreach ($e in $pre) { [void]$all.Add($e) }
    [void]$all.Add($entry)
    $s.hooks | Add-Member -Force -NotePropertyName PreToolUse -NotePropertyValue $all.ToArray()
    $had = Test-Path $settingsPath
    Save-Settings $settingsPath $s
    if ($had) { Write-Host "  updated   settings.json (the guard registered as a PreToolUse hook; backup: settings.json.bak-critos)" }
    else      { Write-Host "  created   settings.json (the guard registered as a PreToolUse hook)" }
}

# --- CLAUDE.md: a single file that may hold your own content -> MERGE one block, never link ---
$global = Get-Content (Join-Path $repo (Join-Path "global" "CLAUDE.global.md")) -Raw -Encoding UTF8
$block  = $beginTag + "`r`n" + $global.TrimEnd() + "`r`n" + $endTag
if (Test-Path $claudeMd) {
    $cur = Get-Content $claudeMd -Raw -Encoding UTF8
    $bi = $cur.IndexOf($beginTag); $ei = $cur.IndexOf($endTag)
    if ($bi -ge 0 -and $ei -gt $bi) {
        $new = $cur.Substring(0, $bi) + $block + $cur.Substring($ei + $endTag.Length)
        if ($new -eq $cur) { Write-Host "  ok        CLAUDE.md (block already current)" }
        else {
            [System.IO.File]::WriteAllText($claudeMd, $new, $utf8)
            Write-Host "  updated   CLAUDE.md (CritOS block replaced)"
        }
    } else {
        [System.IO.File]::WriteAllText($claudeMd, ($cur.TrimEnd() + "`r`n`r`n" + $block + "`r`n"), $utf8)
        Write-Host "  appended  the CritOS block to CLAUDE.md"
    }
} else {
    [System.IO.File]::WriteAllText($claudeMd, ($block + "`r`n"), $utf8)
    Write-Host "  created   CLAUDE.md"
}

Write-Host ""
Write-Host ("Machine ready. This checkout is now a permanent dependency: " + $repo)
Write-Host "Moving the folder breaks every control - run the installer again if you do."
Write-Host "To update: fetch, check out the new release tag, run the installer again."
Write-Host "Restart Claude Code, then run /crit-scaffold-project inside a repo: see docs/guide-install.md"
