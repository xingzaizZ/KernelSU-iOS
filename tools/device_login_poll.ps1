param(
    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dist = "D:\工作台\KernelSU-iOS\dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$deviceFile = Join-Path $dist ".device.json"
$tokenFile  = Join-Path $dist ".token.json"

if (-not (Test-Path $deviceFile)) {
    Write-Host "未找到 device code，请先运行 device_login_request.ps1" -ForegroundColor Red
    exit 1
}

$dev = Get-Content $deviceFile -Raw -Encoding UTF8 | ConvertFrom-Json
$clientId = "178c6fc778ccc68e1d6a"
$h = @{ "Accept" = "application/json"; "User-Agent" = "KernelSU-Builder" }

Write-Host "轮询中，等待你在浏览器完成授权..." -ForegroundColor Cyan
Write-Host "  授权码: $($dev.user_code)" -ForegroundColor Yellow
Write-Host "  地址  : $($dev.verification_uri)" -ForegroundColor Yellow
Write-Host ""

$interval = [int]$dev.interval
if ($interval -lt 5) { $interval = 5 }
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$lastNote = ""

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $interval

    try {
        $r = Invoke-RestMethod -Uri "https://github.com/login/oauth/access_token" -Method Post -Headers $h -Body @{
            "client_id"   = $clientId
            "device_code" = $dev.device_code
            "grant_type"  = "urn:ietf:params:oauth:grant-type:device_code"
        } -TimeoutSec 25
    } catch {
        Write-Host "  请求异常，重试: $($_.Exception.Message)" -ForegroundColor DarkYellow
        continue
    }

    if ($r.access_token) {
        $r | ConvertTo-Json | Set-Content $tokenFile -Encoding UTF8
        Write-Host ""
        Write-Host "授权成功，token 已获取" -ForegroundColor Green
        Write-Host "  类型  : $($r.token_type)"
        Write-Host "  scope : $($r.scope)"
        exit 0
    }

    $err = $r.error
    switch ($err) {
        "authorization_pending" {
            if ($lastNote -ne "pending") {
                Write-Host "  等待授权中..." -ForegroundColor DarkGray
                $lastNote = "pending"
            }
        }
        "slow_down" {
            $interval += 5
            Write-Host "  降低轮询频率到 $interval 秒" -ForegroundColor DarkYellow
        }
        "expired_token" {
            Write-Host "授权码已过期，请重新获取" -ForegroundColor Red
            Remove-Item $deviceFile -Force -ErrorAction SilentlyContinue
            exit 2
        }
        "access_denied" {
            Write-Host "你取消了授权" -ForegroundColor Red
            Remove-Item $deviceFile -Force -ErrorAction SilentlyContinue
            exit 3
        }
        default {
            Write-Host "  未知响应: $($r | ConvertTo-Json -Compress)" -ForegroundColor DarkYellow
        }
    }
}

Write-Host "超时，未完成授权" -ForegroundColor Red
exit 4
