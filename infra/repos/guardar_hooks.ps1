# Guarda el deploy hook de Render de cada microservicio como secret RENDER_DEPLOY_HOOK en su repositorio.
# El valor lo pega la persona en el aviso de gh: nunca queda en el código, en un archivo ni en el historial.
#   & .\infra\repos\guardar_hooks.ps1
$servicios = "gateway", "fleet", "tracking", "shipment", "maintenance", "routing", "notification", "billing"
foreach ($s in $servicios) {
    Write-Host ""
    Write-Host "== $s" -ForegroundColor Cyan
    Write-Host "En Render: tracklogi-$s > Settings > Deploy Hook > icono de copiar. Luego pegalo aqui (no se vera):"
    gh secret set RENDER_DEPLOY_HOOK -R "Kevinso4/logitrack-$s"
}
Write-Host ""
Write-Host "Listo. Secrets guardados:" -ForegroundColor Green
foreach ($s in $servicios) { gh secret list -R "Kevinso4/logitrack-$s" }
