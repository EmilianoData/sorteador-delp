$ErrorActionPreference = 'Stop'
$p = 9876
if ($env:PORT) { $p = [int]$env:PORT }
$r = 'C:\temp\sorteador-delp'

try {
    $l = New-Object System.Net.HttpListener
    $l.Prefixes.Add("http://+:$p/")
    $l.Start()
} catch {
    $l = New-Object System.Net.HttpListener
    $l.Prefixes.Add("http://localhost:$p/")
    $l.Start()
}

[Console]::Error.WriteLine("Serving on http://localhost:$p")
[Console]::Out.WriteLine("Serving on http://localhost:$p")
[Console]::Out.Flush()
[Console]::Error.Flush()

while ($true) {
    try {
        $c = $l.GetContext()
        $u = $c.Request.Url.LocalPath
        if ($u -eq '/') { $u = '/index.html' }
        $f = Join-Path $r ($u.TrimStart('/').Replace('/', '\'))
        if (Test-Path $f -PathType Leaf) {
            $c.Response.StatusCode = 200
            $ext = [IO.Path]::GetExtension($f).ToLower()
            switch ($ext) {
                '.html' { $c.Response.ContentType = 'text/html; charset=utf-8' }
                '.js'   { $c.Response.ContentType = 'application/javascript' }
                '.css'  { $c.Response.ContentType = 'text/css' }
                '.png'  { $c.Response.ContentType = 'image/png' }
                '.svg'  { $c.Response.ContentType = 'image/svg+xml' }
                '.json' { $c.Response.ContentType = 'application/json' }
                default { $c.Response.ContentType = 'application/octet-stream' }
            }
            $b = [IO.File]::ReadAllBytes($f)
            $c.Response.ContentLength64 = $b.Length
            $c.Response.OutputStream.Write($b, 0, $b.Length)
        } else {
            $c.Response.StatusCode = 404
            $msg = [Text.Encoding]::UTF8.GetBytes('Not Found')
            $c.Response.ContentLength64 = $msg.Length
            $c.Response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $c.Response.Close()
    } catch {
        [Console]::Error.WriteLine("Error: $_")
    }
}
