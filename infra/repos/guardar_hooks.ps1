# Guarda el deploy hook de Render de cada microservicio como secret RENDER_DEPLOY_HOOK en su repositorio.
# El valor se pega en un aviso oculto: no queda en pantalla, en archivos ni en el historial de la terminal.
# Antes de guardarlo comprueba que el hook sea del servicio correcto (su URL contiene el id srv-...).
#   & .\infra\repos\guardar_hooks.ps1                       # los 8
#   & .\infra\repos\guardar_hooks.ps1 tracking,shipment     # solo algunos (separados por coma)
param([string[]]$Servicios)
$ids = [ordered]@{
    gateway      = "srv-daqqg449v7es73fo8o10"; fleet        = "srv-daqqf65g1s2s73eijfug"
    tracking     = "srv-daqqfod9fdbs73c06770"; shipment     = "srv-daqqfgs9v7es73fo6np0"
    maintenance  = "srv-daqqfe17lnhs73embsl0"; routing      = "srv-db7bqfo473hc73cpk9mg"
    notification = "srv-db7bqh8473hc73cpki30"; billing      = "srv-db7bqi2d0e5s7381le80"
}
if (-not $Servicios) { $Servicios = $ids.Keys }

foreach ($s in $Servicios) {
    $id = $ids[$s]
    while ($true) {
        Write-Host ""
        Write-Host "== $s" -ForegroundColor Cyan
        Write-Host "1. Abre:  https://dashboard.render.com/web/$id/settings"
        Write-Host "2. Comprueba que arriba diga tracklogi-$s, baja a Deploy Hook y pulsa el icono de copiar."
        $seguro = Read-Host "3. Pega el hook aqui (no se vera) y pulsa Enter" -AsSecureString
        $hook = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($seguro))
        if ($hook.Contains("/" + $id + "?")) { break }
        Write-Host "Ese hook NO es de tracklogi-$s (no contiene $id). Copialo de nuevo desde el enlace de arriba." -ForegroundColor Red
    }
    $hook | gh secret set RENDER_DEPLOY_HOOK -R "Kevinso4/logitrack-$s"
    Remove-Variable hook, seguro
}
Write-Host ""
Write-Host "Listo." -ForegroundColor Green
