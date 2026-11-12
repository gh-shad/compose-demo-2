# =============================================================================
#  Start-Demo.ps1  -  one-click Windows launcher for the Docker Compose demo
#  Double-click Start-Demo.bat (it runs this file). It does everything:
#    1. checks that Multipass is installed
#    2. creates the compose-lab VM the first time (from cloud-init.yaml),
#       or starts it if it already exists
#    3. copies this whole project folder into the VM (~/compose-demo).
#       Your Git history inside the VM (.git) is never touched, and changed
#       files are backed up first (see docs/06-files-explained.md)
#    4. opens the website and Adminer in your browser as soon as they are running
#    5. runs the demo (press Enter once to start it)
#    6. opens your GitHub project page at the end
#  Options are passed on to demo.sh, for example:  Start-Demo.bat --slow
# =============================================================================

$ErrorActionPreference = "Continue"
$VmName   = "compose-lab"
$VmFolder = "/home/ubuntu/compose-demo"
$Here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$Options  = ($args -join " ")
$TarPath  = Join-Path ([System.IO.Path]::GetTempPath()) "compose-demo-update.tar"

function Info($text) { Write-Host "  $text" -ForegroundColor Cyan }
function Good($text) { Write-Host "  [OK] $text" -ForegroundColor Green }
function Stop-WithMessage($text) {
  Write-Host "  [PROBLEM] $text" -ForegroundColor Red
  if (Test-Path $TarPath) { Remove-Item $TarPath -Force -ErrorAction SilentlyContinue }
  Write-Host ""
  Read-Host "  Press Enter to close this window" | Out-Null
  exit 1
}

Write-Host ""
Write-Host "  ==================================================" -ForegroundColor Blue
Write-Host "    Docker Compose Demo  -  Windows launcher" -ForegroundColor White
Write-Host "  ==================================================" -ForegroundColor Blue
Write-Host ""

# 1. Multipass ------------------------------------------------------------------
if (-not (Get-Command multipass -ErrorAction SilentlyContinue)) {
  Stop-WithMessage "Multipass is not installed. Install it from https://canonical.com/multipass/install , restart Windows, and try again."
}
Good "Multipass is installed"

if (-not (Test-Path (Join-Path $Here "demo.sh"))) {
  Stop-WithMessage "demo.sh was not found next to this launcher. Keep all project files together in one folder."
}

# 2. Create or start the VM -------------------------------------------------------
cmd /c "multipass info $VmName >nul 2>&1"
if ($LASTEXITCODE -ne 0) {
  $ci = Join-Path $Here "cloud-init.yaml"
  if (-not (Test-Path $ci)) {
    Stop-WithMessage "cloud-init.yaml was not found. Put it in the same folder as this launcher and try again."
  }
  Info "Creating the demo VM '$VmName'. This happens only the first time and takes about 10 minutes..."
  multipass launch 24.04 --name $VmName --cpus 2 --memory 4G --disk 15G --cloud-init "$ci" --timeout 1500
  if ($LASTEXITCODE -ne 0) { Info "Multipass is still busy. Waiting for the setup to finish..." }
} else {
  Info "Starting the demo VM '$VmName'..."
  multipass start $VmName
  if ($LASTEXITCODE -ne 0) {
    Stop-WithMessage "The VM did not start. Check that your Wi-Fi network is set to Private and that Hyper-V is turned on."
  }
}

Info "Waiting until the VM setup is finished..."
multipass exec $VmName -- cloud-init status --wait | Out-Null
$ready = multipass exec $VmName -- cat /home/ubuntu/LAB-READY.txt 2>$null
if (-not ($ready -match "COMPOSE LAB READY")) {
  Stop-WithMessage "The VM setup did not finish. To see why, run:  multipass exec $VmName -- cloud-init status --long"
}
Good "The VM is ready"

# 3. Copy the project into the VM -------------------------------------------------
#    a) demo.sh first (the newest version knows how to import the rest safely)
multipass exec $VmName -- mkdir -p $VmFolder
multipass transfer (Join-Path $Here "demo.sh") "${VmName}:$VmFolder/demo.sh"
multipass exec $VmName -- bash -c "sed -i 's/\r`$//' $VmFolder/demo.sh && chmod +x $VmFolder/demo.sh"
#    b) everything else as one package (without any .git folder)
if (Test-Path $TarPath) { Remove-Item $TarPath -Force }
tar -cf "$TarPath" --exclude .git -C "$Here" .
if ($LASTEXITCODE -ne 0) { Stop-WithMessage "Could not pack the project files (tar)." }
multipass transfer "$TarPath" "${VmName}:/tmp/compose-demo-update.tar"
Remove-Item $TarPath -Force -ErrorAction SilentlyContinue
multipass exec $VmName -- bash $VmFolder/demo.sh --import-update /tmp/compose-demo-update.tar
if ($LASTEXITCODE -ne 0) { Stop-WithMessage "Could not copy the project into the VM." }
Good "Copied the project into the VM"

# 4. VM address + open the browser pages automatically ---------------------------
$ip = ((multipass exec $VmName -- hostname -I) -split '\s+' | Where-Object { $_ })[0]
Good "VM address: $ip   (website: http://${ip}:8080   Adminer: http://${ip}:8081)"

$browserJob = $null
if ($Options -notmatch "--git-only" -and $Options -notmatch "--setup") {
  $browserJob = Start-Job -ArgumentList $ip -ScriptBlock {
    param($ip)
    $pages    = @("http://${ip}:8080/", "http://${ip}:8081/")
    $opened   = @{}
    $deadline = (Get-Date).AddMinutes(45)
    while ((Get-Date) -lt $deadline -and $opened.Count -lt $pages.Count) {
      foreach ($url in $pages) {
        if (-not $opened.ContainsKey($url)) {
          try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { Start-Process $url; $opened[$url] = $true; Start-Sleep -Seconds 1 }
          } catch { }
        }
      }
      Start-Sleep -Seconds 2
    }
  }
  Info "The website and Adminer will open in your browser by themselves when they start (Part 5)."
  Info "When that happens, click back on this window to keep watching the demo."
}

# 5. Run the demo ------------------------------------------------------------------
Write-Host ""
multipass exec $VmName -- bash -lc "cd $VmFolder && ./demo.sh $Options"
$demoExit = $LASTEXITCODE

# 6. Finish: stop the browser helper, open the GitHub page -------------------------
if ($browserJob) {
  Stop-Job $browserJob -ErrorAction SilentlyContinue
  Remove-Job $browserJob -Force -ErrorAction SilentlyContinue
}
$ghUrl = multipass exec $VmName -- cat /home/ubuntu/.compose-demo-github-url 2>$null | Select-Object -First 1
if ($ghUrl -and $ghUrl.Trim().StartsWith("https://github.com/")) {
  Info "Opening your GitHub project page: $($ghUrl.Trim())"
  Start-Process $ghUrl.Trim()
}

Write-Host ""
if ($demoExit -eq 0) {
  Write-Host "  The demo finished successfully." -ForegroundColor Green
} else {
  Write-Host "  The demo finished with problems. Scroll up to read the [PROBLEM] messages." -ForegroundColor Yellow
}
Read-Host "  Press Enter to close this window" | Out-Null
