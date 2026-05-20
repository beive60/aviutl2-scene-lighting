<#
.SYNOPSIS
	ローカル環境でパッケージング・タグ作成・GitHub Release 作成を一括実行する。

.DESCRIPTION
	以下の 3 ステップを順次実行する:
		1. src 配下の Lua ファイルを .anm2 として staging する
		2. 配布用 zip を作成する
		3. git tag 作成と gh release によるアセットアップロード

.PARAMETER Version
	リリースバージョン文字列 (例: "0.1.0")。
	git tag には "v" プレフィックスが自動付与される。

.EXAMPLE
	.\scripts\release.ps1 -Version "0.1.0"

.NOTES
	前提条件: git, gh CLI がパス上に存在すること。
#>
param(
	[Parameter(Mandatory = $true)]
	[string]$Version
)

$ErrorActionPreference = "Stop"

function Assert-CommandExists {
	param([string]$Command)

	if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
		throw "Required command '$Command' not found in PATH. Please install it and try again."
	}
}

try {
	Write-Host "=== 0/4: Check Prerequisites ==="
	"git", "gh" | ForEach-Object { Assert-CommandExists $_ }
	Write-Host "All prerequisites found."

	Write-Host "=== 1/4: Stage Package Contents ==="

	$repoRoot = Split-Path -Parent $PSScriptRoot
	$sourceDir = Join-Path $repoRoot "src"
	$stagingDir = Join-Path $repoRoot "dist\release"
	$packageRoot = Join-Path $stagingDir "Script\Beive60"

	if (-not (Test-Path $sourceDir)) {
		throw "Source directory not found: $sourceDir"
	}

	if (Test-Path $stagingDir) {
		Remove-Item -Recurse -Force $stagingDir
	}

	New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

	$sourceFiles = Get-ChildItem -Path $sourceDir -Filter "*.lua" -File -Recurse
	if ($sourceFiles.Count -eq 0) {
		throw "No .lua files found under: $sourceDir"
	}

	foreach ($sourceFile in $sourceFiles) {
		$relativePath = $sourceFile.FullName.Substring($sourceDir.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
		$destinationRelativePath = [System.IO.Path]::ChangeExtension($relativePath, ".anm2")
		$destinationPath = Join-Path $packageRoot $destinationRelativePath
		$destinationParent = Split-Path -Parent $destinationPath

		if (-not (Test-Path $destinationParent)) {
			New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
		}

		Copy-Item -Path $sourceFile.FullName -Destination $destinationPath
	}

	Copy-Item -Path (Join-Path $repoRoot "README.md") -Destination $stagingDir
	Copy-Item -Path (Join-Path $repoRoot "LICENSE") -Destination $stagingDir

	Write-Host "Staged package contents at: $stagingDir"

	Write-Host "=== 2/4: Create Zip ==="

	$distDir = Join-Path $repoRoot "dist"
	$zipFileName = "aviutl2-scene-lighting-v$($Version).au2pkg.zip"
	$zipPath = Join-Path $distDir $zipFileName

	if (-not (Test-Path $distDir)) {
		New-Item -ItemType Directory -Path $distDir -Force | Out-Null
	}

	if (Test-Path $zipPath) {
		Remove-Item -Force $zipPath
	}

	Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $zipPath -Force
	Remove-Item -Recurse -Force $stagingDir

	Write-Host "Created release zip: $zipPath"

	Write-Host "=== 3/4: Release ==="

	Write-Host "Checking GitHub CLI authentication status..."
	gh auth status
	if ($LASTEXITCODE -ne 0) {
		throw "GitHub CLI not authenticated. Please run 'gh auth login' and try again."
	}
	Write-Host "GitHub CLI is authenticated."

	git -C $repoRoot tag "v$Version"
	if ($LASTEXITCODE -ne 0) {
		throw "git tag failed."
	}

	git -C $repoRoot push origin "v$Version"
	if ($LASTEXITCODE -ne 0) {
		throw "git push origin v$Version failed."
	}

	gh release create "v$Version" $zipPath --repo beive60/aviutl2-scene-lighting --title "Release v$Version" --generate-notes
	if ($LASTEXITCODE -ne 0) {
		throw "gh release create failed."
	}

	Write-Host "=== 4/4: Done ==="
	Write-Host "Released v$Version successfully."
}
catch {
	Write-Host "`nError during release process:"
	Write-Host "  - $($_.Exception.Message)"
	exit 1
}
