@echo off
REM ==============================================================================
REM AUTOMACAO DIARIA DO PIPELINE DE ETL: GESTAO SEGURA -> SQL SERVER
REM Invocado pelo Agendador de Tarefas do Windows (Task Scheduler)
REM ==============================================================================

cd /d "%~dp0"

if not exist "logs" mkdir logs

echo [%DATE% %TIME%] Iniciando execucao do ETL Gestao Segura (UPSERT)... >> logs\execucao_tarefas.log

python etl_gestao_segura.py upsert >> logs\execucao_tarefas.log 2>&1

set RETORNO=%ERRORLEVEL%
if %RETORNO% EQU 0 (
    echo [%DATE% %TIME%] Execucao finalizada com SUCESSO. Codigo: %RETORNO% >> logs\execucao_tarefas.log
) else (
    echo [%DATE% %TIME%] Execucao finalizada com ERRO. Codigo: %RETORNO% >> logs\execucao_tarefas.log
)

exit /b %RETORNO%
