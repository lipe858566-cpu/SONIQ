$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifest = Join-Path $root 'android/app/src/main/AndroidManifest.xml'
if (-not (Test-Path $manifest)) { throw 'AndroidManifest.xml ausente. Execute flutter create --platforms=android . antes.' }
[xml]$xml = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8
$androidNS = 'http://schemas.android.com/apk/res/android'
$app = $xml.SelectSingleNode('/manifest/application')
if ($null -eq $app) { throw 'Tag application ausente.' }
[void]$app.SetAttribute('label', $androidNS, 'SONIQ')
$permission = 'android.permission.INTERNET'
$found = $false
foreach ($node in @($xml.DocumentElement.SelectNodes('uses-permission'))) {
  if ($node.GetAttribute('name', $androidNS) -eq $permission) { $found = $true; break }
}
if (-not $found) {
  $element = $xml.CreateElement('uses-permission')
  [void]$element.SetAttribute('name', $androidNS, $permission)
  [void]$xml.DocumentElement.InsertBefore($element, $app)
}
$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)
$writer = [System.Xml.XmlWriter]::Create($manifest, $settings)
try { $xml.Save($writer) } finally { $writer.Dispose() }
Write-Host 'SONIQ: nome do aplicativo e permissao de internet configurados.'
