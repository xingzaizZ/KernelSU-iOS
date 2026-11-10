param(
    [Parameter(Mandatory = $true)][string]$Token,
    [string]$Owner = "",
    [string]$Repo = "KernelSU-iOS",
    [string]$Branch = "main",
    [string]$ProjectDir = "D:\工作台\KernelSU-iOS",
    [string]$CommitMessage = "feat: KernelSU iOS 外观外壳（SwiftUI + CI 打包未签名 ipa）"
)

$ErrorActionPreference = "Stop"
$ApiBase = "https://api.github.com"
$Headers = @{
    Authorization          = "Bearer $Token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "KernelSU-iOS-Pusher"
}

function Invoke-GH {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body = $null,
        [switch]$Allow404
    )
    $uri = "$ApiBase$Path"
    $req = @{ Method = $Method; Uri = $uri; Headers = $Headers; ContentType = "application/json" }
    if ($null -ne $Body) { $req.Body = ($Body | ConvertTo-Json -Depth 20 -Compress) }
    try {
        return Invoke-RestMethod @req
    } catch {
        $code = $null
        try { $code = [int]$_.Exception.Response.StatusCode } catch { }
        if ($Allow404 -and $code -eq 404) { return $null }
        $detail = ""
        try {
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $detail = $sr.ReadToEnd()
        } catch { }
        throw "GitHub API 失败 [$Method $Path]: $($_.Exception.Message) $detail"
    }
}

Write-Host "[1/6] 校验 token 与账号..." -ForegroundColor Cyan
$me = Invoke-GH -Method GET -Path "/user"
if (-not $Owner) { $Owner = $me.login }
Write-Host "      账号: $($me.login)  目标仓库: $Owner/$Repo"

Write-Host "[2/6] 确保仓库存在..." -ForegroundColor Cyan
$repoInfo = Invoke-GH -Method GET -Path "/repos/$Owner/$Repo" -Allow404
if (-not $repoInfo) {
    Write-Host "      仓库不存在，创建中（private）..."
    $repoInfo = Invoke-GH -Method POST -Path "/user/repos" -Body @{
        name        = $Repo
        description = "KernelSU iOS 外观外壳：SwiftUI 复刻界面，无真实提权、无模块加载器，CI 直出未签名 ipa"
        private     = $true
        auto_init   = $false
        has_issues  = $true
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "      仓库已存在，直接复用"
}

Write-Host "[3/6] 收集文件..." -ForegroundColor Cyan
$skipDirs  = @(".git", "build", "DerivedData", "__pycache__", "KernelSU-iOS.xcodeproj")
$skipFiles = @("*.log", "*.ipa", ".DS_Store")
$root = (Resolve-Path $ProjectDir).Path
$files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
    $parts = $rel -split '[\\/]'
    $blocked = $false
    foreach ($p in $parts) { if ($skipDirs -contains $p) { $blocked = $true } }
    foreach ($pat in $skipFiles) { if ($_.Name -like $pat) { $blocked = $true } }
    -not $blocked
}
Write-Host "      共 $($files.Count) 个文件"

Write-Host "[4/6] 上传 blobs..." -ForegroundColor Cyan
$treeItems = New-Object System.Collections.ArrayList
$i = 0
foreach ($f in $files) {
    $i++
    $rel = $f.FullName.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64 = [Convert]::ToBase64String($bytes)
    $blob = Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/blobs" -Body @{
        content  = $b64
        encoding = "base64"
    }
    [void]$treeItems.Add(@{
        path = $rel
        mode = "100644"
        type = "blob"
        sha  = $blob.sha
    })
    Write-Host ("      [{0}/{1}] {2}" -f $i, $files.Count, $rel)
}

Write-Host "[5/6] 建立 tree 与 commit..." -ForegroundColor Cyan
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
    message = $CommitMessage
    tree    = $tree.sha
}
if ($parentSha) { $commitBody.parents = @($parentSha) }
$commit = Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/commits" -Body $commitBody

if ($ref) {
    Invoke-GH -Method PATCH -Path "/repos/$Owner/$Repo/git/refs/heads/$Branch" -Body @{
        sha   = $commit.sha
        force = $true
    } | Out-Null
} else {
    Invoke-GH -Method POST -Path "/repos/$Owner/$Repo/git/refs" -Body @{
        ref = "refs/heads/$Branch"
        sha = $commit.sha
    } | Out-Null
}

Write-Host "[6/6] 完成" -ForegroundColor Green
Write-Host ""
Write-Host "仓库地址: https://github.com/$Owner/$Repo"
Write-Host "Actions : https://github.com/$Owner/$Repo/actions"
Write-Host "提交    : $($commit.sha)"
Write-Host ""
Write-Host "下一步：Actions → Build unsigned IPA → Run workflow，跑完在 Artifacts 下载 KernelSU-ios-ipa"
