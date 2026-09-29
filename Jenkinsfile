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
        PYTHONUNBUFFERED = '1'
        ETL_MODO_CARGA   = "${params.MODO_CARGA}"
        
        // Exemplo 1: Se você cadastrou as credenciais individualmente no Jenkins (Recomendado):
        // MJ_CLIENT_ID     = credentials('MJ_CLIENT_ID')
        // MJ_CLIENT_SECRET = credentials('MJ_CLIENT_SECRET')
        // DB_PASSWORD      = credentials('DB_POSTGRES_PASSWORD')
        // DB_USER          = 'user_glaucio'
        // DB_HOST          = '10.91.61.21'
        // DB_PORT          = '5432'
        // DB_NAME          = 'suag'
        // DB_SCHEMA        = 'API_MJ'
    }

    stages {
        stage('Preparar Ambiente') {
            steps {
                // Cria diretório de logs se não existir
                dir('logs') { }
                
                // Instala ou valida as dependências do projeto
                // Funciona tanto em agentes Windows (bat) quanto Linux (sh)
                script {
                    if (isUnix()) {
                        sh '''
                            python3 -m pip install --upgrade pip
                            pip3 install -r requirements.txt
                        '''
                    } else {
                        bat '''
                            python -m pip install --upgrade pip
                            pip install -r requirements.txt
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
                        bat "python etl_gestao_segura.py %MODO_CARGA%"
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
