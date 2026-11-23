param(
    [int]$Port = 5197,
    [string]$WorkbookPath = 'C:\Users\acer\OneDrive\Shastri_Hostel_Test_Credentials_Dataset.xlsx',
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$frontendRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\frontend'))
$frontendPrefix = $frontendRoot.TrimEnd('\') + '\'
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$sessions = @{}
$failures = @{}

function Read-XlsxRows([IO.Compression.ZipArchive]$Archive, [int]$SheetNumber) {
    $entry = $Archive.GetEntry("xl/worksheets/sheet$SheetNumber.xml")
    if (-not $entry) { throw "Workbook sheet $SheetNumber is missing." }
    $stream = $entry.Open()
    $reader = [IO.StreamReader]::new($stream)
    try { $xmlText = $reader.ReadToEnd() }
    finally { $reader.Dispose(); $stream.Dispose() }
    $doc = [xml]$xmlText
    $ns = [Xml.XmlNamespaceManager]::new($doc.NameTable)
    $ns.AddNamespace('m', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
    $result = [Collections.Generic.List[object]]::new()
    foreach ($row in $doc.SelectNodes('//m:sheetData/m:row', $ns)) {
        $values = @{}
        foreach ($cell in $row.SelectNodes('m:c', $ns)) {
            $column = [regex]::Match($cell.GetAttribute('r'), '^[A-Z]+').Value
            $text = $cell.SelectSingleNode('m:is/m:t', $ns)
            $value = $cell.SelectSingleNode('m:v', $ns)
            if ($text) { $values[$column] = $text.InnerText }
            elseif ($value) { $values[$column] = $value.InnerText }
            else { $values[$column] = '' }
        }
        $result.Add($values)
    }
    return $result
}

function Add-DatasetAccount($Map, $Role, $Id, $Name, $Email, $Password, $Profile = @{}) {
    if ([string]::IsNullOrWhiteSpace($Email) -or [string]::IsNullOrWhiteSpace($Password)) { throw "An account in role $Role has a missing email or password." }
    $account = [pscustomobject]@{ Role = $Role; Id = [string]$Id; Name = [string]$Name; Email = ([string]$Email).Trim().ToLowerInvariant(); Password = [string]$Password; Profile = $Profile }
    foreach ($identifier in @($account.Email, $account.Id)) {
        if ([string]::IsNullOrWhiteSpace($identifier)) { continue }
        $key = "$Role|$($identifier.Trim().ToLowerInvariant())"
        if ($Map.ContainsKey($key)) { throw "Duplicate login identifier found in dataset for role $Role." }
        $Map[$key] = $account
    }
}

if (-not (Test-Path -LiteralPath $WorkbookPath -PathType Leaf)) { throw "Credential workbook not found: $WorkbookPath" }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($WorkbookPath)
try {
    $accounts = @{}
    foreach ($r in (Read-XlsxRows $archive 2 | Where-Object { $_['A'] -match '^ADM-' })) { Add-DatasetAccount $accounts 'admin' $r['A'] $r['B'] $r['D'] $r['E'] -Profile @{ designation=$r['C']; phone=$r['F']; accessLevel=$r['G'] } }
    foreach ($r in (Read-XlsxRows $archive 3 | Where-Object { $_['A'] -match '^WDN-' })) { Add-DatasetAccount $accounts 'warden' $r['A'] $r['B'] $r['F'] $r['G'] -Profile @{ designation=$r['C']; hostel=$r['D']; assignedFloors=$r['E']; phone=$r['H']; officeRoom=$r['I']; shift=$r['J'] } }
    foreach ($r in (Read-XlsxRows $archive 4 | Where-Object { $_['A'] -match '^SEC-' })) { Add-DatasetAccount $accounts 'security' $r['A'] $r['B'] $r['G'] $r['H'] -Profile @{ badge=$r['C']; hostel=$r['D']; post=$r['E']; shift=$r['F']; phone=$r['I']; emergencyContact=$r['J'] } }
    foreach ($r in (Read-XlsxRows $archive 5 | Where-Object { $_['B'] -match '^\d' })) {
        $branchYear = [string]$r['H']
        $branchYearDivider = $branchYear.IndexOf(' - ')
        $course = if ($branchYearDivider -ge 0) { $branchYear.Substring(0, $branchYearDivider).Trim() } else { $branchYear }
        $year = if ($branchYearDivider -ge 0) { $branchYear.Substring($branchYearDivider + 3).Trim() } else { '' }
        Add-DatasetAccount $accounts 'student' $r['B'] $r['C'] $r['J'] $r['K'] -Profile @{ gender=$r['D']; hostel=$r['E']; room=$r['F']; bed=$r['G']; course=$course; year=$year; bloodGroup=$r['I']; phone=$r['L']; parentName=$r['M']; parentEmail=$r['N']; parentPhone=$r['P']; feeStatus=$r['Q'] }
        Add-DatasetAccount $accounts 'parent' '' $r['M'] $r['N'] $r['O'] -Profile @{ phone=$r['P']; studentId=$r['B']; studentName=$r['C']; studentEmail=$r['J']; course=$course; year=$year; hostel=$r['E']; room=$r['F'] }
    }
} finally { $archive.Dispose() }

function Read-HttpRequest($Stream) {
    $headerBuffer = [IO.MemoryStream]::new()
    try {
        while ($headerBuffer.Length -lt 65536) {
            $b = $Stream.ReadByte()
            if ($b -lt 0) { return $null }
            $headerBuffer.WriteByte([byte]$b)
            $arr = $headerBuffer.ToArray()
            $n = $arr.Length
            if ($n -ge 4 -and $arr[$n-4] -eq 13 -and $arr[$n-3] -eq 10 -and $arr[$n-2] -eq 13 -and $arr[$n-1] -eq 10) { break }
        }
        $text = [Text.Encoding]::ASCII.GetString($headerBuffer.ToArray())
        $lines = $text -split "`r`n"
        if ($lines.Count -lt 2) { return $null }
        $start = $lines[0] -split ' ', 3
        $headers = @{}
        foreach ($line in $lines | Select-Object -Skip 1) {
            if (-not $line) { break }
            $split = $line.IndexOf(':')
            if ($split -gt 0) { $headers[$line.Substring(0,$split).Trim().ToLowerInvariant()] = $line.Substring($split+1).Trim() }
        }
        $length = 0
        if ($headers.ContainsKey('content-length')) { [int]::TryParse($headers['content-length'], [ref]$length) | Out-Null }
        $body = New-Object byte[] $length
        $offset = 0
        while ($offset -lt $length) { $read = $Stream.Read($body, $offset, $length - $offset); if ($read -le 0) { break }; $offset += $read }
        return [pscustomobject]@{ Method = $start[0]; Target = $start[1]; Headers = $headers; Body = $body }
    } finally { $headerBuffer.Dispose() }
}

function Send-HttpResponse($Stream, [int]$Status, [string]$ContentType, [byte[]]$Body, [string[]]$ExtraHeaders = @()) {
    $reason = switch ($Status) { 200 {'OK'} 302 {'Found'} 401 {'Unauthorized'} 403 {'Forbidden'} 404 {'Not Found'} 429 {'Too Many Requests'} default {'Internal Server Error'} }
    $headerText = "HTTP/1.1 $Status $reason`r`nContent-Type: $ContentType`r`nContent-Length: $($Body.Length)`r`nConnection: close`r`nX-Content-Type-Options: nosniff`r`nReferrer-Policy: same-origin`r`n"
    foreach ($header in $ExtraHeaders) { $headerText += "$header`r`n" }
    $headerBytes = [Text.Encoding]::ASCII.GetBytes($headerText + "`r`n")
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($Body.Length) { $Stream.Write($Body, 0, $Body.Length) }
    $Stream.Flush()
}

function Send-Json($Stream, [int]$Status, $Data, [string[]]$ExtraHeaders = @()) {
    $body = [Text.Encoding]::UTF8.GetBytes(($Data | ConvertTo-Json -Compress -Depth 5))
    Send-HttpResponse $Stream $Status 'application/json; charset=utf-8' $body $ExtraHeaders
}

function Get-SessionFromHeaders($Headers) {
    if (-not $Headers.ContainsKey('cookie')) { return $null }
    $match = [regex]::Match($Headers['cookie'], '(?:^|;\s*)hms_session=([^;]+)')
    if (-not $match.Success) { return $null }
    $token = $match.Groups[1].Value
    if (-not $sessions.ContainsKey($token)) { return $null }
    if ($sessions[$token].Expires -le [DateTime]::UtcNow) { $sessions.Remove($token); return $null }
    return @{ Token = $token; Value = $sessions[$token] }
}

function New-SessionToken {
    $bytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
}

function Test-FixedTimeEqual([byte[]]$Left, [byte[]]$Right) {
    if ($Left.Length -ne $Right.Length) { return $false }
    $difference = 0
    for ($i = 0; $i -lt $Left.Length; $i++) { $difference = $difference -bor ($Left[$i] -bxor $Right[$i]) }
    return $difference -eq 0
}

$mime = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.svg'='image/svg+xml'; '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.ico'='image/x-icon' }
$uniqueAccounts = @{}
foreach ($account in $accounts.Values) { $uniqueAccounts["$($account.Role)|$($account.Email)"] = $true }
Write-Host "Validated $($uniqueAccounts.Count) accounts from the supplied workbook."
if ($ValidateOnly) {
    $required = @('admin|ADM-001', 'warden|WDN-01', 'security|SEC-01', 'student|25101001', 'parent|rajendra.sharma01@gmail.com')
    foreach ($key in $required) { if (-not $accounts.ContainsKey($key)) { throw "Credential validation failed for role key $($key.Split('|')[0])." } }
    $sampleAccount = $accounts['admin|ADM-001']
    if (-not (Test-FixedTimeEqual ([Text.Encoding]::UTF8.GetBytes($sampleAccount.Password)) ([Text.Encoding]::UTF8.GetBytes($sampleAccount.Password))) -or (Test-FixedTimeEqual ([Text.Encoding]::UTF8.GetBytes($sampleAccount.Password)) ([Text.Encoding]::UTF8.GetBytes(($sampleAccount.Password + '-wrong'))))) { throw 'Credential comparison validation failed.' }
    if ($accounts.ContainsKey('student|not-in-workbook')) { throw 'Out-of-dataset account validation failed.' }
    Write-Host 'Credential membership and password comparison checks passed.'
    exit 0
}
$listener.Start()
Write-Host "Hostel Management test portal: http://127.0.0.1:$Port/"
Write-Host 'The workbook passwords stay in the server process. Press Ctrl+C to stop.'

try {
    while ($listener) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 10000
            $client.SendTimeout = 10000
            $stream = $client.GetStream()
            $request = Read-HttpRequest $stream
            if (-not $request) { continue }
            $uri = [Uri]::new("http://127.0.0.1:$Port$($request.Target)")
            $path = [Uri]::UnescapeDataString($uri.AbsolutePath)

            if ($path -eq '/api/login' -and $request.Method -eq 'POST') {
                $ip = $client.Client.RemoteEndPoint.Address.ToString()
                if ($failures.ContainsKey($ip) -and $failures[$ip].Until -gt [DateTime]::UtcNow) {
                    Send-Json $stream 429 @{ error = 'Too many failed attempts. Try again later.' }; continue
                }
                try { $body = [Text.Encoding]::UTF8.GetString($request.Body) | ConvertFrom-Json } catch { Send-Json $stream 401 @{ error = 'Invalid credentials for this portal.' }; continue }
                $role = ([string]$body.role).Trim().ToLowerInvariant()
                $identifier = ([string]$body.identifier).Trim().ToLowerInvariant()
                $key = "$role|$identifier"
                $account = if ($accounts.ContainsKey($key)) { $accounts[$key] } else { $null }
                $passwordBytes = [Text.Encoding]::UTF8.GetBytes([string]$body.password)
                $expectedBytes = if ($account) { [Text.Encoding]::UTF8.GetBytes($account.Password) } else { [Text.Encoding]::UTF8.GetBytes('invalid-account-password-sentinel') }
                $validPassword = Test-FixedTimeEqual $passwordBytes $expectedBytes
                if (-not $account -or -not $validPassword) {
                if (-not $failures.ContainsKey($ip) -or $failures[$ip].Until -le [DateTime]::UtcNow) { $failures[$ip] = @{ Count = 0; Until = [DateTime]::MinValue } }
                    $failures[$ip].Count++
                    if ($failures[$ip].Count -ge 8) { $failures[$ip].Until = [DateTime]::UtcNow.AddMinutes(15) }
                    Send-Json $stream 401 @{ error = 'Invalid credentials for this portal.' }; continue
                }
                $failures.Remove($ip)
                $token = New-SessionToken
                $sessions[$token] = @{ Role = $account.Role; Id = $account.Id; Name = $account.Name; Email = $account.Email; Profile = $account.Profile; Expires = [DateTime]::UtcNow.AddHours(8) }
                $cookie = "Set-Cookie: hms_session=$token; Path=/; HttpOnly; SameSite=Strict; Max-Age=28800"
                Send-Json $stream 200 @{ role = $account.Role; name = $account.Name } @($cookie)
                continue
            }

            $currentSession = Get-SessionFromHeaders $request.Headers
            if ($path -eq '/api/session' -and $request.Method -eq 'GET') {
                if (-not $currentSession) { Send-Json $stream 401 @{ error = 'Login required.' }; continue }
                $session = $currentSession.Value
                Send-Json $stream 200 @{ role = $session.Role; id = $session.Id; email = $session.Email; name = $session.Name; profile = $session.Profile }
                continue
            }

            if ($path -eq '/api/logout' -and $request.Method -eq 'POST') {
                if ($currentSession) { $sessions.Remove($currentSession.Token) }
                Send-Json $stream 200 @{ ok = $true } @('Set-Cookie: hms_session=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0')
                continue
            }

            if ($path -eq '/') { $path = '/index.html' }
            $dashboardSession = $null
            if ($path -match '^/(student|parent|warden|security|admin)/dashboard\.html$') {
                $wantedRole = $Matches[1]
                if (-not $currentSession -or $currentSession.Value.Role -ne $wantedRole) {
                    $redirect = "Location: /$wantedRole/login.html"
                    Send-HttpResponse $stream 302 'text/plain; charset=utf-8' ([byte[]]@()) @($redirect)
                    continue
                }
                $dashboardSession = $currentSession.Value
            }

            $relativePath = $path.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
            $filePath = [IO.Path]::GetFullPath((Join-Path $frontendRoot $relativePath))
            if (-not $filePath.StartsWith($frontendPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                Send-HttpResponse $stream 404 'text/plain; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes('Not found.')); continue
            }
            $extension = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
            $contentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
            $fileBytes = [IO.File]::ReadAllBytes($filePath)
            if ($dashboardSession -and $extension -eq '.html') {
                $safeSession = @{ role=$dashboardSession.Role; id=$dashboardSession.Id; email=$dashboardSession.Email; name=$dashboardSession.Name; profile=$dashboardSession.Profile }
                $sessionJson = $safeSession | ConvertTo-Json -Compress -Depth 5
                $sessionJson = $sessionJson.Replace('</', '<\/')
                $html = [Text.Encoding]::UTF8.GetString($fileBytes)
                $html = $html.Replace('<head>', "<head><script>window.HMS_AUTH_USER=$sessionJson;</script>")
                $fileBytes = [Text.Encoding]::UTF8.GetBytes($html)
            }
            Send-HttpResponse $stream 200 $contentType $fileBytes
        } catch {
            Write-Warning $_.Exception.Message
            try { Send-HttpResponse $client.GetStream() 500 'text/plain; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes('Server error.')) } catch { }
        } finally { $client.Dispose() }
    }
} finally { $listener.Stop() }
