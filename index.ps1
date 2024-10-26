$httpListener = New-Object System.Net.HttpListener
$httpListener.Prefixes.Add("http://localhost:5000/")
$httpListener.Start()

$running = $true

while ($running) {
    $context = $httpListener.GetContext()
    Write-Host $context
    $request = $context.Request
    Write-Host $request
    Write-Host $context.request.HttpMethod
    
    if ($request.Url.AbsolutePath -eq "/close") {
        if ($context.request.HttpMethod -eq "GET") {
            $running = $false
            $context.Response.StatusCode = 200
            $context.Response.ContentType = "text/plain"
            $context.Response.OutputStream.Write([Text.Encoding]::UTF8.GetBytes("Shutting down..."), 0, 13)
        }
    }
    else {
        # Mapeando os endpoints
        if ($request.Url.AbsolutePath -eq "/menu") {
            if ($context.request.HttpMethod -eq "GET") {
                if ($auth) {
                    $context.Response.StatusCode = 200
                    $context.Response.ContentType = "text/HTML"
                    $webContent = Get-Content -Path "./templates/index.html" -Encoding UTF8
                    $encodedWebContent = [Text.Encoding]::UTF8.GetBytes($webContent)
                    $context.Response.OutputStream.Write($encodedWebContent, 0, $encodedWebContent.Length)
                }
                else {
                    $context.Response.StatusCode = 302
                    $context.Response.RedirectLocation = "/login"
                    $context.Response.Close()
                }
            }
        }

        if ($request.Url.AbsolutePath -eq "/login") {
            if ($context.request.HttpMethod -eq "GET") {
                $auth = $false
                $context.Response.StatusCode = 200
                $context.Response.ContentType = "text/HTML"
                $webContent = Get-Content -Path "./templates/login.html" -Encoding UTF8
                $encodedWebContent = [Text.Encoding]::UTF8.GetBytes($webContent)
                $context.Response.OutputStream.Write($encodedWebContent, 0, $encodedWebContent.Length)
            }
            else {
                $requestBody = [System.IO.StreamReader]::new($request.InputStream).ReadToEnd()
                $formData = [System.Web.HttpUtility]::ParseQueryString($requestBody)
                if (!($formData["Email"])) {

                    $user = $formData["Name_In"]
                    $password = $formData["Password_In"]
                    $users = Import-Csv -Path "./users.csv"
    
                    $usuario = $users | Where-Object { $_.username -eq $user }
                    Write-Host $usuario
                    if ($usuario) {
                        Write-Host 'Usuário Existe'
                        if ($usuario.pword -eq $password) {
                            Write-Host 'Senha Correta!'
                            $auth = $true
                            Write-Host 'Autentificado: '$auth
                            $context.Response.StatusCode = 302
                            $context.Response.RedirectLocation = "/menu"
                            $context.Response.Close()
                        }
                        else {
                            Write-Host 'Senha incorreta'
                        }
                    }
                    else {
                        Write-Host 'Senha Errada!'
                    }
                }
                else {
                    $user_register = $formData["Name"]
                    $password_register = $formData["Password"]
                    $email = $formData["Email"]
                    
                    $new_register = [PSCustomObject]@{
                        username = $user_register
                        pword    = $password_register
                        role     = "user"
                        email    = $email
                    }

                    $csvpath = "./users.csv"

                    if (Test-Path $csvpath) {
                        $users_data = Import-Csv -Path $csvpath
                        $users_data = @($users_data)

                        $users_data += $new_register
    
                        $users_data | Export-Csv -Path $csvpath -NoTypeInformation

                        #Add welcome Screen
                    }
                    else {
                       #Redirect to error msg
                    }
                }
            }
        }

        if ($request.Url.AbsolutePath -eq "/") {
            if ($context.request.HttpMethod -eq "GET") {
                $context.Response.StatusCode = 302
                $context.Response.RedirectLocation = "/login"
                $context.Response.Close()
            }
        }
        
    }

    
    

    $context.Response.Close()
}

$httpListener.Stop()