$port = if ($env:PORT) { $env:PORT } else { 9876 }
$root = $PSScriptRoot
$prefix = "http://localhost:${port}/"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.Start()

[Console]::Out.WriteLine("Serving on http://localhost:${port}")
[Console]::Out.Flush()

$mimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css'
    '.js'   = 'application/javascript'
    '.json' = 'application/json'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $reqPath = $ctx.Request.Url.LocalPath
        if ($reqPath -eq '/') { $reqPath = '/index.html' }
        $filePath = Join-Path $root ($reqPath.TrimStart('/').Replace('/', '\'))

        $ctx.Response.AddHeader('Access-Control-Allow-Origin', '*')
        $ctx.Response.AddHeader('Cache-Control', 'no-cache')

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { 'application/octet-stream' }
            $ctx.Response.ContentType = $mime
            $ctx.Response.StatusCode = 200
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
            $ctx.Response.ContentType = 'text/plain'
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $reqPath")
            $ctx.Response.ContentLength64 = $msg.Length
            $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $ctx.Response.Close()
    }
} finally {
    $listener.Stop()
}
