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
                        powershell '''
                            Write-Host "=== 1. Localizando interpretador Python no servidor Jenkins ==="
                            
                            $candidates = @(
                                "C:\\Program Files\\Python312\\python.exe",
                                "C:\\Program Files\\Python311\\python.exe",
                                "C:\\Program Files\\Python310\\python.exe",
                                "C:\\Python312\\python.exe",
                                "C:\\Python311\\python.exe",
                                "C:\\Python310\\python.exe",
                                "C:\\tools\\python\\python.exe"
                            )

                            # Busca em perfis de usuários
                            $userPythons = Get-ChildItem "C:\\Users\\*\\AppData\\Local\\Programs\\Python\\Python3*\\python.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
                            if ($userPythons) {
                                $candidates += $userPythons
                            }

                            # Busca no PATH excluindo o atalho da Microsoft Store
                            $pathPythons = (Get-Command python.exe -All -ErrorAction SilentlyContinue | Where-Object { $_.Source -notmatch "WindowsApps" }) | Select-Object -ExpandProperty Source
                            if ($pathPythons) {
                                $candidates += $pathPythons
                            }

                            $pyExe = $null
                            foreach ($c in $candidates) {
                                if (Test-Path $c) {
                                    $pyExe = $c
                                    break
                                }
                            }

                            if (-not $pyExe) {
                                Write-Error "ERRO CRITICO: Python nao foi encontrado no servidor Jenkins (10.91.254.37). Instale o Python 3 neste servidor."
                                exit 1
                            }

                            Write-Host "Python localizado com sucesso em: $pyExe"
                            Set-Content -Path "python_path.txt" -Value $pyExe -Force

                            Write-Host "=== 2. Instalando / Validando dependencias ==="
                            & $pyExe -m pip install --upgrade pip
                            & $pyExe -m pip install -r requirements.txt
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
                        powershell '''
                            $pyExe = Get-Content -Path "python_path.txt" -Raw
                            $pyExe = $pyExe.Trim()
                            Write-Host "Executando ETL com: $pyExe"
                            & $pyExe etl_gestao_segura.py $env:MODO_CARGA
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
