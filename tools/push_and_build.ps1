param(
    [Parameter(Mandatory = $true)][string]$Token,
    [string]$Owner = "",
    [string]$Repo = "KernelSU-iOS",
    [string]$Branch = "main",
    [string]$ProjectDir = "D:\工作台\KernelSU-iOS",
    [string]$OutDir = "D:\工作台\KernelSU-iOS\dist",
    [switch]$Public,
    [int]$WaitMinutes = 45
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ApiBase = "https://api.github.com"
$Headers = @{
    Authorization          = "Bearer $Token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "KernelSU-iOS-Builder"
}

function Invoke-GH {
    param([string]$Method, [string]$Path, [object]$Body = $null, [switch]$Allow404)
    $req = @{
        Method      = $Method
        Uri         = "$ApiBase$Path"
        Headers     = $Headers
        ContentType = "application/json"
    }
    if ($null -ne $Body) { $req.Body = ($Body | ConvertTo-Json -Depth 20 -Compress) }
    try {
        return Invoke-RestMethod @req
    } catch {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch { }
        if ($Allow404 -and $code -eq 404) { return $null }
        $detail = ""
        try {
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $detail = $sr.ReadToEnd()
        } catch { }
        throw "GitHub API error [$Method $Path] HTTP $code : $($_.Exception.Message) $detail"
    }
}

function Step($n, $total, $msg) {
    Write-Host ""
    Write-Host "[$n/$total] $msg" -ForegroundColor Cyan
}

$TOTAL = 8

Step 1 $TOTAL "校验 token"
$me = $null
try {
    $me = Invoke-GH -Method GET -Path "/user"
} catch {
    Write-Host "  token 无效或权限不足。" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkGray
    exit 1
}
if (-not $Owner) { $Owner = $me.login }
Write-Host "  用户: $($me.login)" -ForegroundColor Green
Write-Host "  仓库: $Owner/$Repo"

try {
    $r = Invoke-WebRequest -Uri "$ApiBase/user" -Headers $Headers -Method Head -UseBasicParsing
    $scopes = $r.Headers["x-oauth-scopes"]
    if ($scopes) { Write-Host "  token scopes: $scopes" }
} catch { }

Step 2 $TOTAL "准备仓库"
$repoInfo = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo" -Allow404
if (-not $repoInfo) {
    $isPrivate = -not $Public.IsPresent
    Write-Host "  创建新仓库（private=$isPrivate）..."
    $body = @{
        name        = $Repo
        description = "KernelSU iOS shell: SwiftUI UI replica, no real privilege escalation, no module loader, CI builds unsigned ipa"
        private     = $isPrivate
        auto_init   = $false
        has_issues  = $true
    }
    $repoInfo = Invoke-GH -Method POST -Path "/user/repos" -Body $body
    Start-Sleep -Seconds 3
    Write-Host "  已创建" -ForegroundColor Green
} else {
    Write-Host "  仓库已存在，复用" -ForegroundColor Yellow
}

$repoUrl = $repoInfo.html_url
Write-Host "  $repoUrl"

Step 3 $TOTAL "收集待上传文件"
$skipDirs = @(".git", "build", "DerivedData", "__pycache__", "KernelSU-iOS.xcodeproj", "dist", "_upstream")
$skipFiles = @("*.log", "*.ipa", ".DS_Store", "*.pyc")
$root = (Resolve-Path $ProjectDir).Path

$files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
    $parts = $rel -split '[\\/]'
    $blocked = $false
    foreach ($p in $parts) { if ($skipDirs -contains $p) { $blocked = $true } }
    foreach ($pat in $skipFiles) { if ($_.Name -like $pat) { $blocked = $true } }
    -not $blocked
}
Write-Host "  共 $($files.Count) 个文件"

Step 4 $TOTAL "上传文件内容"
$treeItems = New-Object System.Collections.ArrayList
$i = 0
foreach ($f in $files) {
    $i++
    $rel = $f.FullName.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $blob = Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/blobs" -Body @{
        content  = [Convert]::ToBase64String($bytes)
        encoding = "base64"
    }
    [void]$treeItems.Add(@{ path = $rel; mode = "100644"; type = "blob"; sha = $blob.sha })
    Write-Host "  ($i/$($files.Count)) $rel" -ForegroundColor DarkGray
}

Step 5 $TOTAL "建立 tree 与 commit"
$ref = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/git/ref/heads/$Branch" -Allow404
$parentSha = $null
$baseTree = $null
if ($ref) {
    $parentSha = $ref.object.sha
    $parentCommit = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/git/commits/$parentSha"
    $baseTree = $parentCommit.tree.sha
}

$treeBody = @{ tree = $treeItems }
if ($baseTree) { $treeBody.base_tree = $baseTree }
$tree = Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/trees" -Body $treeBody

$commitBody = @{
    message = "feat: KernelSU iOS shell with original icon and CI ipa build"
    tree    = $tree.sha
}
if ($parentSha) { $commitBody.parents = @($parentSha) }
$commit = Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/commits" -Body $commitBody

if ($ref) {
    Invoke-GH -Method PATCH -Path "/repos/$Owner/$Repo/git/refs/heads/$Branch" -Body @{ sha = $commit.sha; force = $true } | Out-Null
} else {
    Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/refs" -Body @{ ref = "refs/heads/$Branch"; sha = $commit.sha } | Out-Null
}
Write-Host "  commit: $($commit.sha)" -ForegroundColor Green

Step 6 $TOTAL "触发 GitHub Actions"
Start-Sleep -Seconds 8

$runId = $null
for ($try = 0; $try -lt 6 -and -not $runId; $try++) {
    $runs = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/actions/runs?branch=$Branch&per_page=5" -Allow404
    if ($runs -and $runs.workflow_runs.Count -gt 0) {
        $runId = $runs.workflow_runs[0].id
        Write-Host "  发现 run: $runId"
        break
    }
    Start-Sleep -Seconds 4
}

if (-not $runId) {
    Write-Host "  未自动触发，手动 dispatch..."
    try {
        Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/actions/workflows/build-ipa.yml/dispatches" -Body @{ ref = $Branch } | Out-Null
    } catch {
        Write-Host "  dispatch 失败，继续轮询..." -ForegroundColor Yellow
    }
    for ($try = 0; $try -lt 15 -and -not $runId; $try++) {
        Start-Sleep -Seconds 5
        $runs = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/actions/runs?branch=$Branch&per_page=5" -Allow404
        if ($runs -and $runs.workflow_runs.Count -gt 0) { $runId = $runs.workflow_runs[0].id }
    }
}

if (-not $runId) {
    Write-Host "  无法定位 workflow run，请打开：" -ForegroundColor Red
    Write-Host "  $repoUrl/actions" -ForegroundColor Yellow
    exit 1
}

Write-Host "  run: $repoUrl/actions/runs/$runId" -ForegroundColor Green

Step 7 $TOTAL "等待 macOS runner 构建（上限 $WaitMinutes 分钟）"
$deadline = (Get-Date).AddMinutes($WaitMinutes)
$lastStatus = ""
$conclusion = $null

while ((Get-Date) -lt $deadline) {
    $run = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/actions/runs/$runId"
    $st = "$($run.status)/$($run.conclusion)"
    if ($st -ne $lastStatus) {
        Write-Host "  $(Get-Date -Format 'HH:mm:ss')  status=$($run.status)  conclusion=$($run.conclusion)" -ForegroundColor DarkCyan
        $lastStatus = $st
    }
    if ($run.status -eq "completed") {
        $conclusion = $run.conclusion
        break
    }
    Start-Sleep -Seconds 15
}

if ($conclusion -ne "success") {
    Write-Host ""
    Write-Host "  构建未成功: $conclusion" -ForegroundColor Red
    try {
        $jobs = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/actions/runs/$runId/jobs"
        foreach ($j in $jobs.jobs) {
            Write-Host "  --- job: $($j.name) -> $($j.conclusion) ---" -ForegroundColor Yellow
            foreach ($s in $j.steps) {
                $mark = "FAIL"
                if ($s.conclusion -eq "success") { $mark = "OK  " }
                if ($s.conclusion -eq "skipped") { $mark = "--  " }
                Write-Host "    [$mark] $($s.name)"
            }
        }
    } catch { }
    Write-Host ""
    Write-Host "  完整日志: $repoUrl/actions/runs/$runId" -ForegroundColor Yellow
    exit 1
}

Write-Host "  构建成功" -ForegroundColor Green

Step 8 $TOTAL "下载未签名 ipa"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$arts = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo/actions/runs/$runId/artifacts"
$art = $null
foreach ($a in $arts.artifacts) { if ($a.name -eq "KernelSU-ios-ipa") { $art = $a } }
if (-not $art) {
    Write-Host "  未找到 artifact: KernelSU-ios-ipa" -ForegroundColor Red
    foreach ($a in $arts.artifacts) { Write-Host "    实际存在: $($a.name)" }
    exit 1
}

$zipPath = Join-Path $OutDir "KernelSU-ios-artifact.zip"
Write-Host "  artifact: $($art.name)  ($([math]::Round($art.size_in_bytes/1MB,2)) MB)"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "$ApiBase/repos/$Owner/$Repo/actions/artifacts/$($art.id)/zip" `
                  -Headers $Headers -OutFile $zipPath -UseBasicParsing
Write-Host "  已下载到: $zipPath"

$extractDir = Join-Path $OutDir "extract"
if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

$ipa = Get-ChildItem -Path $extractDir -Filter "*.ipa" -Recurse | Select-Object -First 1
if (-not $ipa) {
    Write-Host "  artifact 内未找到 .ipa" -ForegroundColor Red
    Get-ChildItem -Recurse $extractDir | ForEach-Object { Write-Host "    $($_.FullName)" }
    exit 1
}

$finalIpa = Join-Path $OutDir $ipa.Name
Move-Item -Path $ipa.FullName -Destination $finalIpa -Force
Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  DONE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Repo   : $repoUrl"
Write-Host "  Actions: $repoUrl/actions/runs/$runId"
Write-Host "  IPA    : $finalIpa" -ForegroundColor Yellow
Write-Host "  Size   : $([math]::Round((Get-Item $finalIpa).Length/1MB,2)) MB"
