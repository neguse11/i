# カレントディレクトリをコピー先とする
[string]$CM3D2_MOD_DIR=$pwd

# 以下のコードなら、スクリプトの配置場所がコピー先になる
# $CM3D2_MOD_DIR=Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path

# レジストリからインストール情報を取得
$CM3D2_VANILLA_DIR=$CM3D2_REGISTORY = (Get-ItemProperty "HKCU:\Software\KISS\カスタムメイド3D2").InstallPath



# シンボリックリンクを作る関数
# http://tech.guitarrapc.com/entry/2014/08/19/022232
function Set-SymbolicLinkFile([string]$Path, [string]$SymbolicNewPath)
{
    Add-Type -Namespace SymbolicLink -Name Utils -MemberDefinition @"
internal static class Win32 {
	[DllImport("kernel32.dll", SetLastError = true)]
	[return: MarshalAs(UnmanagedType.I1)]
	public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, SymLinkFlag dwFlags);

	internal enum SymLinkFlag { File = 0, Directory = 1 }
}

public static void CreateSymLinkFile(string name, string target) {
	if (!Win32.CreateSymbolicLink(name, target, Win32.SymLinkFlag.File))
	{
	    throw new System.ComponentModel.Win32Exception();
	}
}
"@
	[SymbolicLink.Utils]::CreateSymLinkFile($SymbolicNewPath, $Path)
}

# バニラのファイル構造を取得
$vanillaDirs = Get-ChildItem -path $CM3D2_VANILLA_DIR -recurse | where { $_.mode -match "d" }
$vanillaFiles = Get-ChildItem -path $CM3D2_VANILLA_DIR -recurse | where { ! $_.PSIsContainer }

# ディレクトリを作る
foreach ($dir in $vanillaDirs) {
	$rel = $dir.FullName -replace [regex]::Escape($CM3D2_VANILLA_DIR), ""
	$modDirName = $CM3D2_MOD_DIR + $rel
	if(! (Test-Path $modDirName)) {
		Write-Host $modDirName
		New-Item -Force -ItemType directory -Path $modDirName | Out-Null
	}
}

# シンボリックリンクを作る
foreach ($file in $vanillaFiles) {
	$vanillaFileName = $file.FullName
	$rel = $file.FullName -replace [regex]::Escape($CM3D2_VANILLA_DIR), ""
	$modFileName = $CM3D2_MOD_DIR + $rel

	# ファイルが存在しなければ
	if(! (Test-Path $modFileName)) {
		if($rel -match "GameData\\") {
			# GameData下はシンボリックリンクを生成
			Set-SymbolicLinkFile -Path $vanillaFileName -SymbolicNewPath $modFileName
		} else {
			# その他はコピー
			Write-Host "COPY : " $rel
			Copy-Item $vanillaFileName $modFileName
		}
	}
}
