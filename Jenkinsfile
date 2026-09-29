pipeline {
    agent any

    // Agendamento diário: roda toda madrugada às 03:00 (H distribui a carga no Jenkins)
    triggers {
        cron('H 3 * * *')
    }

    parameters {
        choice(
            name: 'MODO_CARGA',
            choices: ['upsert', 'replace'],
            description: 'Modo de carga do ETL: upsert (incremental/padrão) ou replace (sobrescreve tabelas)'
        )
    }

    options {
        timeout(time: 2, unit: 'HOURS') // Evita que jobs fiquem presos indefinidamente
        buildDiscarder(logRotator(numToKeepStr: '30')) // Mantém histórico dos últimos 30 builds
        timestamps()
    }

    // Configuração de credenciais e variáveis sensíveis cadastradas no Jenkins:
    // Manage Jenkins -> Credentials -> System -> Global credentials
    environment {
        // Adiciona ao PATH o diretório de instalação do Python e Scripts no Windows
        PATH = "C:\\Users\\glaucio.silva\\AppData\\Local\\Programs\\Python\\Python312;C:\\Users\\glaucio.silva\\AppData\\Local\\Programs\\Python\\Python312\\Scripts;C:\\Python312;C:\\Python312\\Scripts;${env.PATH}"
        PYTHONUNBUFFERED = '1'
        ETL_MODO_CARGA   = "${params.MODO_CARGA}"
        
        // Exemplo: se configurado via Credentials no Jenkins:
        // MJ_CLIENT_ID     = credentials('MJ_CLIENT_ID')
        // MJ_CLIENT_SECRET = credentials('MJ_CLIENT_SECRET')
        // DB_PASSWORD      = credentials('DB_POSTGRES_PASSWORD')
    }

    stages {
        stage('Preparar Ambiente') {
            steps {
                dir('logs') { }
                
                script {
                    if (isUnix()) {
                        sh '''
                            python3 -m pip install --upgrade pip
                            pip3 install -r requirements.txt
                        '''
                    } else {
                        bat '''
                            @echo off
                            echo === 1. Localizando interpretador Python no servidor ===
                            set "PY_EXE="

                            REM Procura por python.exe em locais padrao de instalacao do Windows
                            for %%P in (
                                "C:\\Python312\\python.exe"
                                "C:\\Python311\\python.exe"
                                "C:\\Python310\\python.exe"
                                "C:\\Python39\\python.exe"
                                "C:\\Program Files\\Python312\\python.exe"
                                "C:\\Program Files\\Python311\\python.exe"
                                "C:\\Program Files\\Python310\\python.exe"
                                "C:\\Program Files\\Python39\\python.exe"
                                "C:\\Program Files (x86)\\Python312\\python.exe"
                                "C:\\Program Files (x86)\\Python311\\python.exe"
                                "C:\\Program Files (x86)\\Python310\\python.exe"
                                "C:\\ProgramData\\chocolatey\\bin\\python.exe"
                            ) do (
                                if exist %%P if not defined PY_EXE set "PY_EXE=%%~P"
                            )

                            REM Se nao encontrou em locais padrao do sistema, busca nos perfis de usuarios
                            if not defined PY_EXE (
                                for /d %%U in ("C:\\Users\\*") do (
                                    if exist "%%U\\AppData\\Local\\Programs\\Python\\Python312\\python.exe" (
                                        set "PY_EXE=%%U\\AppData\\Local\\Programs\\Python\\Python312\\python.exe"
                                    ) else if exist "%%U\\AppData\\Local\\Programs\\Python\\Python311\\python.exe" (
                                        set "PY_EXE=%%U\\AppData\\Local\\Programs\\Python\\Python311\\python.exe"
                                    ) else if exist "%%U\\AppData\\Local\\Programs\\Python\\Python310\\python.exe" (
                                        set "PY_EXE=%%U\\AppData\\Local\\Programs\\Python\\Python310\\python.exe"
                                    )
                                )
                            )

                            if not defined PY_EXE (
                                echo ERRO CRITICO: Python nao foi encontrado instalado no servidor Jenkins (10.91.254.37).
                                echo Verifique se o Python 3.10+ esta instalado neste servidor ou configurado nas variaveis de ambiente do sistema.
                                exit /b 1
                            )

                            echo Python localizado com sucesso em: "%PY_EXE%"
                            echo %PY_EXE% > python_path.txt

                            echo === 2. Verificando configuracao do .env ===
                            if not exist ".env" (
                                echo AVISO: Arquivo .env nao localizado no workspace.
                                echo O script utilizara as variaveis de ambiente configuradas no Jenkins.
                            )

                            echo === 3. Instalando / Validando dependencias ===
                            "%PY_EXE%" -m pip install --upgrade pip
                            "%PY_EXE%" -m pip install -r requirements.txt
                        '''
                    }
                }
            }
        }

        stage('Executar ETL Gestão Segura') {
            steps {
                script {
                    echo "Iniciando Pipeline de ETL - Modo: ${params.MODO_CARGA}"
                    
                    if (isUnix()) {
                        sh "python3 etl_gestao_segura.py ${params.MODO_CARGA}"
                    } else {
                        bat '''
                            @echo off
                            set /p PY_EXE=<python_path.txt
                            if not defined PY_EXE set "PY_EXE=python"
                            "%PY_EXE%" etl_gestao_segura.py %MODO_CARGA%
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            // Arquiva os arquivos de log gerados para auditoria na interface do Jenkins
            archiveArtifacts artifacts: 'logs/*.log', fingerprint: true, allowEmptyArchive: true
        }
        success {
            echo "Pipeline de ETL executado com SUCESSO!"
        }
        failure {
            echo "ALERTA: Falha na execução do Pipeline de ETL! Verifique os logs anexados."
            // Se tiver plugin de e-mail ou Slack/Teams configurado:
            // mail to: 'equipe@ssp.df.gov.br', subject: "Falha ETL MJ: Job ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "Verifique o build em ${env.BUILD_URL}"
        }
    }
}
