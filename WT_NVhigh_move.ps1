# =========================================
# ShadowPlay War Thunder
# Moment of death 重複整理【完全最終版】
# ・ミリ秒2～4桁対応
# ・日付跨ぎ対応
# ・判定範囲拡張
# ・各場面で1本だけ残す
# =========================================

# --- 設定 ---
$maxSpan = 40    # 同一場面とみなす最大秒数
$moveDir = "MomentOfDeath_Duplicates"

# 年月日＋時刻＋ミリ秒（2～4桁）
$pattern = '(\d{4})\.(\d{2})\.(\d{2}) - (\d{2})\.(\d{2})\.(\d{2})\.(\d{2,4})\.Moment of death'

# --- 移動先フォルダ作成 ---
if (-not (Test-Path $moveDir)) {
    New-Item -ItemType Directory -Path $moveDir | Out-Null
}

# --- ファイル取得 & 日時解析 ---
$files = Get-ChildItem -Filter "*.mp4" |
    Where-Object { $_.Name -match "Moment of death" } |
    ForEach-Object {
        if ($_.Name -match $pattern) {

            # ミリ秒正規化
            $msRaw = $matches[7]
            switch ($msRaw.Length) {
                2 { $ms = [int]$msRaw * 10 }
                3 { $ms = [int]$msRaw }
                default { $ms = [int]$msRaw.Substring(0,3) } # 4桁以上
            }

            $dt = [datetime]::new(
                [int]$matches[1],
                [int]$matches[2],
                [int]$matches[3],
                [int]$matches[4],
                [int]$matches[5],
                [int]$matches[6],
                $ms
            )

            [PSCustomObject]@{
                File = $_
                Time = $dt
            }
        }
    } |
    Sort-Object Time

# --- 同一場面ごとにグループ化 ---
$groups = @()
$current = @()
$groupStart = $null

foreach ($f in $files) {
    if ($current.Count -eq 0) {
        $current = @($f)
        $groupStart = $f.Time
        continue
    }

    $span = [math]::Abs(($f.Time - $groupStart).TotalSeconds)

    if ($span -le $maxSpan) {
        $current += $f
    } else {
        $groups += ,$current
        $current = @($f)
        $groupStart = $f.Time
    }
}
if ($current.Count -gt 0) { $groups += ,$current }

# --- 各グループで「最後の1本」以外を移動 ---
foreach ($g in $groups) {
    if ($g.Count -gt 1) {
        $g[0..($g.Count-2)] | ForEach-Object {
            Move-Item $_.File.FullName $moveDir
        }
    }
}

Write-Host "完了：4桁ミリ秒含めて整理しました（$maxSpan 秒・1本残し）"
