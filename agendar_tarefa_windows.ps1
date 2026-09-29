<#
.SYNOPSIS
    Script PowerShell para criar/atualizar a Tarefa Agendada no Windows Task Scheduler.
.DESCRIPTION
    Registra a rotina diária de extração da API Gestão Segura e carga incremental (UPSERT)
    no SQL Server.
.EXAMPLE
    .\agendar_tarefa_windows.ps1 -Horario "03:00"
#>

param(
    [string]$NomeTarefa = "ETL_Gestao_Segura_Diario",
    [string]$Horario = "03:00"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$batchPath = Join-Path $scriptDir "executar_etl_diario.bat"

if (-not (Test-Path $batchPath)) {
    Write-Error "O arquivo batch de execução não foi encontrado em: $batchPath"
    exit 1
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " CONFIGURAÇÃO DA TAREFA AGENDADA - WINDOWS TASK SCHEDULER" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Nome da Tarefa : $NomeTarefa" -ForegroundColor Yellow
Write-Host "Horário Diário : $Horario" -ForegroundColor Yellow
Write-Host "Executável     : $batchPath" -ForegroundColor Yellow
Write-Host "Diretório Base : $scriptDir" -ForegroundColor Yellow
Write-Host "-----------------------------------------------------------------"

# Definição da ação
$Acao = New-ScheduledTaskAction -Execute $batchPath -WorkingDirectory $scriptDir

# Definição do gatilho diário
$Gatilho = New-ScheduledTaskTrigger -Daily -At $Horario

# Definição das configurações gerais (reexecução em caso de falha, manter acordado, etc.)
$Configuracoes = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Registro da Tarefa
try {
    # Se já existir, remove para recriar com os novos parâmetros
    Unregister-ScheduledTask -TaskName $NomeTarefa -Confirm:$false -ErrorAction SilentlyContinue
    
    Register-ScheduledTask -TaskName $NomeTarefa -Action $Acao -Trigger $Gatilho -Settings $Configuracoes -Description "Carga diária incremental (UPSERT) da API Gestão Segura (SENASP/MJSP) para o banco INTEGRA_SSP no SQL Server."
    
    Write-Host "`nTarefa agendada registrada com SUCESSO!" -ForegroundColor Green
    Write-Host "Para executar manualmente para teste: Start-ScheduledTask -TaskName '$NomeTarefa'" -ForegroundColor Gray
} catch {
    Write-Error "Falha ao registrar a tarefa agendada: $_"
}
