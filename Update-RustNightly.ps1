$ErrorActionPreference = 'Stop'

function Update-RustNightly(
  [string] $RustupExe = 'rustup.exe',
  [string] $RustupDir,
  [string] $Toolchain,
  [int] $Tries = 30) {

  if (-not $RustupDir) {
    $RustupDir = [IO.Path]::Combine($HOME, '.rustup')
  }

  function Invoke-Rustup([string[]] $RustupArgs) {
    & $RustupExe $RustupArgs
  }

  function Write-Prefixed([string] $Prefix, [ConsoleColor] $Color, [string] $Message) {
    Write-Host "[$Prefix] " -NoNewLine -ForegroundColor $Color

    $UseColor = $false

    foreach ($Part in $Message.Split([char]0x007B, [char]0x007D)) {
      if ($UseColor) {
        Write-Host $Part -NoNewline -ForegroundColor $Color
      } else {
        Write-Host $Part -NoNewline
      }
      $UseColor = -not $UseColor
    }

    Write-Host
  }

  # Find toolchain, channel and target triple
  if (-not $Toolchain) {
    $ToolchainMatch = Invoke-Rustup 'toolchain', 'list' | Select-String '(.+?) \(default\)'
    $Toolchain = $ToolchainMatch.Matches[0].Groups[1].Value
  }

  Write-Prefixed 'i' Blue "Using toolchain {$Toolchain}."

  $Channel = $Toolchain.Substring(0, $Toolchain.IndexOf('-'))
  $Target = $Toolchain.Substring($Channel.Length + 1)

  Write-Prefixed 'i' Blue "Using channel {$Channel}."
  Write-Prefixed 'i' Blue "Using target triple {$Target}."


  # Find needed components
  $Components = Invoke-Rustup 'component', 'list', '--toolchain', $Toolchain `
              | Select-String '(.+?) \('                                     `
              | % { $_.Matches } | % { $_.Groups[1].Value }
  
  Write-Prefixed 'i' Blue "Found {$($Components.Count)} needed components."


  # Find first release that works
  $Date = [datetime]::Now
  $MinDate = $Date.AddDays(-$Tries)

  while ($Date -gt $MinDate) {
    $DateString = $Date.ToString("yyyy-MM-dd")
    $Date = $Date.AddDays(-1)

    Write-Prefixed 'i' Blue "Trying {$DateString}..."

    try {
      $Req = iwr "https://static.rust-lang.org/dist/$DateString/channel-rust-$Channel.toml"
      $Content = $Req.Content

      if ($Content -isnot [string]) {
        $Content = [Text.Encoding]::UTF8.GetString($Content)
      }

      $MatchingComponents = $Components | % {
        $ComponentName = $_.Replace("-$Target", '')
        $Content | Select-String "\[pkg.$ComponentName(?:\.target\.$Target)?\]\s+available = true"
      }

      if ($MatchingComponents -contains $null) {
        Write-Prefixed '-' Yellow "Components were missing in {$DateString}, trying previous day..."
        continue
      }

      # We got a match!
      $NewToolchain = "$Channel-$DateString-$Target"

      Write-Prefixed '+' Green "Match found, installing {$NewToolchain}..."
      Invoke-Rustup 'toolchain', 'install', $NewToolchain

      if (-not $?) {
        Write-Prefixed '!' Red "Failed to install {$NewToolchain}, trying previous day..."
        continue
      }

      # Move newly downloaded toolchain to original toolchain
      $ToolchainsPath = [IO.Path]::Combine($RustupDir, 'toolchains')
      $CurrentToolchainPath = Join-Path $ToolchainsPath -ChildPath $Toolchain
      $NewToolchainPath     = Join-Path $ToolchainsPath -ChildPath $NewToolchain

      if (Test-Path $CurrentToolchainPath) {
        mv $CurrentToolchainPath "$CurrentToolchainPath-old" -Force
      }

      mv $NewToolchainPath $CurrentToolchainPath -Force

      # Replace hash as well
      $HashesPath = [IO.Path]::Combine($RustupDir, 'update-hashes')
      $CurrentToolchainHashPath = Join-Path $HashesPath -ChildPath $Toolchain
      $NewToolchainHashPath     = Join-Path $HashesPath -ChildPath $NewToolchain

      if (Test-Path $CurrentToolchainHashPath) {
        mv $CurrentToolchainHashPath "$CurrentToolchainHashPath-old" -Force
      }

      mv $NewToolchainHashPath $CurrentToolchainHashPath -Force

      Write-Prefixed '+' Green "Toolchain successfully updated."

      return
    } catch {
      Write-Prefixed '!' Red "Failed to add {$DateString}, trying previous day..."
      continue
    }
  }

  Write-Prefixed '-' Yellow "Could not find a suitable match in last $Tries days."
}
