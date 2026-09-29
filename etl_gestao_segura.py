"""
Pipeline de ETL: API Gestão Segura (SENASP/MJSP) -> PostgreSQL
----------------------------------------------------------------
Script modularizado para autenticação OAuth 2.0 (Client Credentials),
extração paginada de dados dos 20 recursos da API (Planejamento, Execução
de Empenho, Pagamentos, Contas do Fundo, Bens e Patrimônio e Catálogo),
com carga automatizada e incremental (UPSERT nativo) no PostgreSQL
(Banco suag / Schema API_MJ).

Autor: Gláucio Silveira e Silva - ASGED
Data: Setembro de 2026
Versão: 2.0 (Suporte aos 20 endpoints da API Gestão Segura)
"""

import os
import sys
import logging
import json
import time
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
from urllib.parse import quote_plus

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

import requests
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

# Carregamento automático de variáveis do arquivo .env
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# ==============================================================================
# CONFIGURAÇÃO DE LOGGING
# ==============================================================================
DIR_LOGS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
os.makedirs(DIR_LOGS, exist_ok=True)
arquivo_log = os.path.join(DIR_LOGS, f"etl_{datetime.now().strftime('%Y%m%d')}.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(arquivo_log, encoding="utf-8")
    ]
)
logger = logging.getLogger("ETL_GESTAO_SEGURA")

# ==============================================================================
# PARÂMETROS E VARIÁVEIS DE CONFIGURAÇÃO
# ==============================================================================
# 1. Configurações da API Gestão Segura (SENASP/MJSP)
API_BASE_URL: str = os.getenv("MJ_API_BASE_URL", "https://apps.mj.gov.br/ws_20250508093400")
API_TOKEN_URL: str = f"{API_BASE_URL}/oauth/token"

# Credenciais institucionais (OAuth 2.0 - Client Credentials)
CLIENT_ID: str = os.getenv("MJ_CLIENT_ID", "")
CLIENT_SECRET: str = os.getenv("MJ_CLIENT_SECRET", "")

# 2. Configurações de Conexão com o Banco de Dados PostgreSQL
DB_HOST: str = os.getenv("DB_HOST", os.getenv("DB_SERVER", "10.91.61.21"))
DB_PORT: str = os.getenv("DB_PORT", "5432")
DB_NAME: str = os.getenv("DB_NAME", os.getenv("DB_DATABASE", "suag"))
DB_USER: str = os.getenv("DB_USER", "user_glaucio")
DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
DB_SCHEMA: str = os.getenv("DB_SCHEMA", "API_MJ")
DB_SSLMODE: str = os.getenv("DB_SSLMODE", "prefer")

# Modo de Carga: 'upsert' (atualiza existentes e insere novos) ou 'replace' (sobrescreve tabelas)
ETL_MODO_CARGA: str = os.getenv("ETL_MODO_CARGA", "upsert").lower()

# ==============================================================================
# MAPEAMENTO COMPLETO DOS 20 ENDPOINTS DA API GESTÃO SEGURA
# ==============================================================================
ENDPOINTS_CONFIG: Dict[str, Dict[str, str]] = {
    # MÓDULO 1: TABELA DE REFERÊNCIA NACIONAL
    "catalogo": {
        "endpoint": "/api/v1/catalogo",
        "tabela": "tb_catalogo",
        "primary_key": "pk_gstb021",
        "descricao": "Catálogo Nacional de Materiais e Serviços"
    },
    # MÓDULO 2: PLANEJAMENTO (CONSULTAS ORIGINAIS)
    "planos_aplicacao": {
        "endpoint": "/api/v1/planos-aplicacao",
        "tabela": "tb_planos_aplicacao",
        "primary_key": "pk_gstb023",
        "descricao": "Planos de Aplicação Gerais"
    },
    "planos_acao": {
        "endpoint": "/api/v1/planos-acao",
        "tabela": "tb_planos_acao",
        "primary_key": "pk_gstb041",
        "foreign_key": "fk_gstb023",
        "descricao": "Planos de Ação Vigentes"
    },
    "metas": {
        "endpoint": "/api/v1/metas",
        "tabela": "tb_metas",
        "primary_key": "pk_gstb042",
        "foreign_key": "fk_gstb041",
        "descricao": "Metas dos Planos de Ação"
    },
    "itens_contratacao": {
        "endpoint": "/api/v1/itens-contratacao",
        "tabela": "tb_itens_contratacao",
        "primary_key": "pk_gstb025",
        "foreign_key": "fk_gstb042",
        "descricao": "Itens de Contratação Planejados"
    },
    # MÓDULO 3: CONTAS DO FUNDO E GESTÃO FINANCEIRA
    "contas": {
        "endpoint": "/api/v1/contas",
        "tabela": "tb_contas",
        "primary_key": "pk_gstb009",
        "foreign_key": "fk_gstb023",
        "descricao": "Contas Bancárias Vinculadas"
    },
    "repasses": {
        "endpoint": "/api/v1/repasses",
        "tabela": "tb_repasses",
        "primary_key": "pk_gstb028",
        "foreign_key": "fk_gstb009",
        "descricao": "Repasses Recebidos do Fundo"
    },
    "rendimentos": {
        "endpoint": "/api/v1/rendimentos",
        "tabela": "tb_rendimentos",
        "primary_key": "pk_gstb030",
        "foreign_key": "fk_gstb009",
        "descricao": "Rendimentos de Aplicação Bancária"
    },
    "liberacoes": {
        "endpoint": "/api/v1/liberacoes",
        "tabela": "tb_liberacoes",
        "primary_key": "pk_gstb031",
        "foreign_key": "fk_gstb009",
        "descricao": "Liberações de Recurso (Ofício/SEI)"
    },
    "saldos_auditoria": {
        "endpoint": "/api/v1/saldos-auditoria",
        "tabela": "tb_saldos_auditoria",
        "primary_key": "pk_gstb035",
        "foreign_key": "fk_gstb009",
        "descricao": "Histórico de Saldos para Auditoria"
    },
    # MÓDULO 4: EXECUÇÃO DO EMPENHO
    "empenhos": {
        "endpoint": "/api/v1/empenhos",
        "tabela": "tb_empenhos",
        "primary_key": "pk_gstb014",
        "descricao": "Empenhos (Licitação, Fornecedor e Valores)"
    },
    "empenhos_plano": {
        "endpoint": "/api/v1/empenhos-plano",
        "tabela": "tb_empenhos_plano",
        "primary_key": "pk_gstb033",
        "foreign_key": "fk_gstb014",
        "descricao": "Vinculo Empenho <-> Item Planejado"
    },
    "documentos": {
        "endpoint": "/api/v1/documentos",
        "tabela": "tb_documentos",
        "primary_key": "pk_gstb016",
        "foreign_key": "fk_gstb014",
        "descricao": "Documentos de Suporte (Notas e Comprovantes)"
    },
    "empenho_documentos": {
        "endpoint": "/api/v1/empenho-documentos",
        "tabela": "tb_empenho_documentos",
        "primary_key": "pk_gstb056",
        "foreign_key": "fk_gstb016",
        "descricao": "Vínculo Empenho ↔ Documento (Fracionamento)"
    },
    # MÓDULO 5: PAGAMENTOS BANCÁRIOS (TRANSFEREGOV)
    "pagamentos": {
        "endpoint": "/api/v1/pagamentos",
        "tabela": "tb_pagamentos",
        "primary_key": "pk_gstb015",
        "foreign_key": "fk_gstb016",
        "descricao": "Execuções e Pagamentos Bancários TransfereGov"
    },
    "documento_pagamentos": {
        "endpoint": "/api/v1/documento-pagamentos",
        "tabela": "tb_documento_pagamentos",
        "primary_key": "pk_gstb054",
        "foreign_key": "fk_gstb015",
        "descricao": "Vínculo Documento ↔ Pagamento (Fracionamento)"
    },
    "pagamento_observacoes": {
        "endpoint": "/api/v1/pagamento-observacoes",
        "tabela": "tb_pagamento_observacoes",
        "primary_key": "pk_gstb036",
        "foreign_key": "fk_gstb015",
        "descricao": "Observações Registradas nas Execuções"
    },
    # MÓDULO 6: BENS E PATRIMÔNIO
    "bens_servicos": {
        "endpoint": "/api/v1/bens-servicos",
        "tabela": "tb_bens_servicos",
        "primary_key": "pk_gstb017",
        "foreign_key": "fk_gstb016",
        "descricao": "Bens e Serviços Adquiridos (Suporte a Documento)"
    },
    "patrimonios": {
        "endpoint": "/api/v1/patrimonios",
        "tabela": "tb_patrimonios",
        "primary_key": "pk_gstb018",
        "foreign_key": "fk_gstb017",
        "descricao": "Tombamento Patrimonial"
    },
    "itens_plan_exec": {
        "endpoint": "/api/v1/itens-plan-exec",
        "tabela": "tb_itens_plan_exec",
        "primary_key": "pk_gstb061",
        "foreign_key": "fk_gstb025",
        "descricao": "Vínculo Item Planejado ↔ Bem Executado"
    }
}


# ==============================================================================
# MÓDULO 1: AUTENTICAÇÃO OAUTH 2.0
# ==============================================================================
def obter_token_acesso(
    token_url: str,
    client_id: str,
    client_secret: str,
    timeout: int = 30
) -> str:
    """
    Realiza a autenticação no provedor OAuth 2.0 via fluxo Client Credentials
    com autenticação HTTP Basic.

    Regra Crítica:
        O backend Oracle APEX exige estritamente o header 'Accept: application/json',
        caso contrário retorna HTML contendo página de erro.
    """
    logger.info("Solicitando novo token de acesso OAuth 2.0...")

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    payload = {
        "grant_type": "client_credentials"
    }

    try:
        response = requests.post(
            url=token_url,
            auth=(client_id, client_secret),
            headers=headers,
            data=payload,
            timeout=timeout
        )

        if response.status_code != 200:
            logger.error(
                "Falha na autenticação OAuth. Status Code: %s | Resposta: %s",
                response.status_code,
                response.text
            )
            response.raise_for_status()

        dados_token = response.json()
        token = dados_token.get("access_token")
        expires_in = dados_token.get("expires_in", 3600)

        if not token:
            raise ValueError("O payload de resposta não continha o campo 'access_token'.")

        logger.info("Token obtido com sucesso! Validade informada: %s segundos.", expires_in)
        return token

    except requests.exceptions.RequestException as e:
        logger.error("Erro de comunicação HTTP ao solicitar token de autenticação: %s", e)
        raise


# ==============================================================================
# MÓDULO 2: EXTRAÇÃO DE DADOS COM PAGINAÇÃO ROBUSTA
# ==============================================================================
def extrair_dados_paginados(
    base_url: str,
    endpoint: str,
    token: str,
    limite_padrao: int = 25,
    timeout: int = 60
) -> List[Dict[str, Any]]:
    """
    Realiza a extração completa de um endpoint REST paginado da API Gestão Segura.

    Regra de Paginação:
        - Os itens estão na chave 'items' do JSON de resposta.
        - 'hasMore' indica se existem páginas subsequentes.
        - Inicia-se com offset=0 e incrementa-se o valor de 'limit' a cada ciclo.
        - Para endpoints volumosos como /pagamentos e /patrimonios, registra progresso
          detalhado e aplica retentativas automáticas em caso de intermitência.
    """
    url_completa = f"{base_url}{endpoint}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json"
    }

    todos_itens: List[Dict[str, Any]] = []
    offset = 0
    pagina = 1
    max_tentativas = 3

    logger.info("Iniciando extração do endpoint: %s", endpoint)

    while True:
        parametros = {
            "offset": offset,
            "limit": limite_padrao
        }

        sucesso_requisicao = False
        payload = {}

        for tentativa in range(1, max_tentativas + 1):
            try:
                response = requests.get(
                    url=url_completa,
                    headers=headers,
                    params=parametros,
                    timeout=timeout
                )

                if response.status_code == 200:
                    payload = response.json()
                    sucesso_requisicao = True
                    break
                else:
                    logger.warning(
                        "Tentativa %s/%s | Erro HTTP %s em %s (offset: %s): %s",
                        tentativa, max_tentativas, response.status_code, endpoint, offset, response.text[:200]
                    )
                    time.sleep(2)
            except requests.exceptions.RequestException as e:
                logger.warning(
                    "Tentativa %s/%s | Falha de rede em %s (offset: %s): %s",
                    tentativa, max_tentativas, endpoint, offset, e
                )
                time.sleep(3)

        if not sucesso_requisicao:
            raise RuntimeError(f"Falha definitiva ao consultar {endpoint} no offset {offset} após {max_tentativas} tentativas.")

        itens_pagina = payload.get("items", [])
        has_more = payload.get("hasMore", False)
        limit_retornado = payload.get("limit", limite_padrao)
        contagem_pagina = len(itens_pagina)

        todos_itens.extend(itens_pagina)

        # Log a cada página para endpoints rápidos ou a cada 4 páginas (100 registros) em volumosos
        if pagina % 4 == 0 or not has_more or contagem_pagina == 0:
            logger.info(
                "Página %s | Offset: %s | Registros obtidos: %s | Total acumulado: %s",
                pagina,
                offset,
                contagem_pagina,
                len(todos_itens)
            )

        if not has_more:
            logger.info("Fim da paginação para %s. Total extraído: %s registros.", endpoint, len(todos_itens))
            break

        offset += limit_retornado
        pagina += 1

    return todos_itens


# ==============================================================================
# MÓDULO 3: TRATAMENTO E TRANSFORMAÇÃO DE DADOS (PANDAS)
# ==============================================================================
def transformar_dados(itens: List[Dict[str, Any]]) -> pd.DataFrame:
    """
    Converte os itens brutos retornados pela API em DataFrame Pandas higienizado:
    - Adiciona coluna de controle de auditoria de carga: dt_carga.
    - Remove atributos auxiliares de HATEOAS (ex.: coluna 'links').
    - Serializa objetos ou listas aninhadas em strings JSON para evitar erros no banco.
    - Normaliza campos de data/hora se aplicável.
    """
    if not itens:
        return pd.DataFrame()

    df = pd.DataFrame(itens)

    # Remover hiperlinks HATEOAS do Oracle APEX/ORDS se existirem no registro
    if "links" in df.columns:
        df = df.drop(columns=["links"])

    # Serialização de colunas aninhadas (dict/list) para JSON string
    for col in df.columns:
        amostra = df[col].dropna().iloc[0] if not df[col].dropna().empty else None
        if isinstance(amostra, (dict, list)):
            df[col] = df[col].apply(lambda x: json.dumps(x, ensure_ascii=False) if isinstance(x, (dict, list)) else x)

    # Conversão de colunas com nomenclatura de data/hora
    colunas_data = [
        col for col in df.columns
        if ("data_" in col or "_data" in col or col.startswith("dt_")) and not col.endswith("_id")
    ]
    for col in colunas_data:
        try:
            df[col] = pd.to_datetime(df[col])
        except Exception:
            pass

    # Coluna de metadados para auditoria da carga
    df["dt_carga"] = datetime.now()

    return df


# ==============================================================================
# MÓDULO 4: CONEXÃO E CARGA NO BANCO DE DADOS (POSTGRESQL)
# ==============================================================================
def criar_conexao_postgresql(
    host: str,
    port: str,
    database: str,
    user: str,
    password: str,
    sslmode: str = "prefer"
) -> Engine:
    """
    Cria a engine SQLAlchemy configurada para o PostgreSQL via Psycopg2.
    Aplica quote_plus nas credenciais para garantir suporte a caracteres especiais.
    """
    user_esc = quote_plus(user)
    pass_esc = quote_plus(password)
    engine_url = f"postgresql+psycopg2://{user_esc}:{pass_esc}@{host}:{port}/{database}?sslmode={sslmode}"

    logger.info(
        "Criando engine SQLAlchemy para o PostgreSQL (Host: %s:%s, Banco: %s, Usuário: %s, SSL: %s)...",
        host,
        port,
        database,
        user,
        sslmode
    )
    return create_engine(engine_url, pool_pre_ping=True)


def verificar_tabela_existe(engine: Engine, schema: str, nome_tabela: str) -> bool:
    """Verifica se uma tabela existe no schema indicado."""
    sql = text("""
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = :schema AND table_name = :tabela;
    """)
    with engine.connect() as conn:
        res = conn.execute(sql, {"schema": schema, "tabela": nome_tabela}).fetchone()
        return bool(res)


def alinhar_colunas_tabelas(engine: Engine, schema: str, tabela_destino: str, colunas_df: List[str]) -> None:
    """
    Compara as colunas do DataFrame extraído com a tabela de destino no PostgreSQL.
    Caso a API tenha retornado campos novos, adiciona as colunas automaticamente no destino.
    """
    sql_cols = text("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = :schema AND table_name = :tabela;
    """)
    try:
        with engine.begin() as conn:
            cols_existentes = {row[0].lower() for row in conn.execute(sql_cols, {"schema": schema, "tabela": tabela_destino}).fetchall()}

            for col in colunas_df:
                if col.lower() not in cols_existentes:
                    logger.info("Nova coluna detectada na API: adicionando '%s' (TEXT) na tabela '\"%s\".\"%s\"'...", col, schema, tabela_destino)
                    conn.execute(text(f'ALTER TABLE "{schema}"."{tabela_destino}" ADD COLUMN IF NOT EXISTS "{col}" TEXT NULL;'))
    except Exception as e:
        logger.warning("Não foi possível alinhar colunas automaticamente em '\"%s\".\"%s\"': %s", schema, tabela_destino, e)


def carregar_dados_postgresql(
    df: pd.DataFrame,
    nome_tabela: str,
    primary_key: str,
    engine: Engine,
    modo_carga: str = "upsert",
    schema: str = "API_MJ"
) -> Tuple[int, int]:
    """
    Executa a carga dos dados no PostgreSQL com suporte a:
    - 'upsert': Carga incremental que atualiza registros existentes e insere novos (ON CONFLICT nativo).
      Usa tabela temporária ou staging com fallback para compatibilidade de permissões.
    - 'replace': Limpa a tabela preservando a estrutura de DDL/PKs e insere os registros.
    """
    if df.empty:
        logger.warning("DataFrame vazio para a tabela '\"%s\".\"%s\"'. Carga ignorada.", schema, nome_tabela)
        return 0, 0

    # 1. Verifica se a tabela de destino existe
    if not verificar_tabela_existe(engine, schema, nome_tabela):
        logger.warning(
            "Tabela '\"%s\".\"%s\"' ainda NÃO existe no banco de dados. "
            "Execute o script 'ddl_postgresql_api_mj.sql' com um usuário DBA/administrador para criá-la. Carga adiada.",
            schema,
            nome_tabela
        )
        raise RuntimeError(f"Tabela de destino '{schema}.{nome_tabela}' inexistente no PostgreSQL.")

    # 2. Garante alinhamento preventivo de novas colunas
    alinhar_colunas_tabelas(engine, schema, nome_tabela, list(df.columns))

    # 3. Modo Replace: Truncate preservando DDL/PKs e Append
    if modo_carga == "replace":
        logger.info("Executando carga em modo REPLACE na tabela '\"%s\".\"%s\"' (%s registros)...", schema, nome_tabela, len(df))
        with engine.begin() as conn:
            conn.execute(text(f'TRUNCATE TABLE "{schema}"."{nome_tabela}" CASCADE;'))
        df.to_sql(name=nome_tabela, con=engine, schema=schema, if_exists="append", index=False, chunksize=1000)
        logger.info("Carga REPLACE concluída com sucesso na tabela '%s'!", nome_tabela)
        return len(df), 0

    # 4. Modo UPSERT (Incremental via tabela temporária / staging e ON CONFLICT)
    logger.info("Executando carga em modo UPSERT na tabela '\"%s\".\"%s\"' (PK: %s, %s registros)...", schema, nome_tabela, primary_key, len(df))

    # Staging no mesmo schema da tabela de destino
    staging_schema = schema
    tabela_staging = f"stg_{nome_tabela}"

    df.to_sql(name=tabela_staging, con=engine, schema=staging_schema, if_exists="replace", index=False, chunksize=1000)


    try:
        colunas = list(df.columns)
        cols_insert = ", ".join([f'"{c}"' for c in colunas])

        # Mapeamento de tipos reais das colunas no PostgreSQL para coerção segura (evita DatatypeMismatch)
        sql_tipos = text("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = :schema AND table_name = :tabela;
        """)
        with engine.connect() as conn:
            tipos_map = {row[0].lower(): row[1].lower() for row in conn.execute(sql_tipos, {"schema": schema, "tabela": nome_tabela}).fetchall()}

        cols_select_list = []
        for c in colunas:
            t = tipos_map.get(c.lower(), "")
            if any(k in t for k in ("bigint", "integer", "smallint", "numeric", "double precision", "real", "timestamp", "date", "boolean")):
                cols_select_list.append(f'NULLIF(stg."{c}"::text, \'\')::{t} AS "{c}"')
            else:
                cols_select_list.append(f'stg."{c}"')
        cols_select = ", ".join(cols_select_list)

        # Cláusula de atualização ON CONFLICT DO UPDATE
        update_set_parts = [
            f'"{c}" = EXCLUDED."{c}"'
            for c in colunas
            if c != primary_key
        ]
        clausula_update = ", ".join(update_set_parts)


        if update_set_parts and primary_key in colunas:
            sql_upsert = f"""
            INSERT INTO "{schema}"."{nome_tabela}" ({cols_insert})
            SELECT {cols_select}
            FROM "{staging_schema}"."{tabela_staging}" AS stg
            ON CONFLICT ("{primary_key}")
            DO UPDATE SET {clausula_update}
            RETURNING xmax;
            """
        else:
            sql_upsert = f"""
            INSERT INTO "{schema}"."{nome_tabela}" ({cols_insert})
            SELECT {cols_select}
            FROM "{staging_schema}"."{tabela_staging}" AS stg
            ON CONFLICT ("{primary_key}") DO NOTHING
            RETURNING xmax;
            """

        inserted = 0
        updated = 0
        with engine.begin() as conn:
            result = conn.execute(text(sql_upsert))
            for row in result:
                if row[0] == 0:
                    inserted += 1
                else:
                    updated += 1
            logger.info("Instrução UPSERT (ON CONFLICT) executada com sucesso entre '%s.%s' e '%s.%s'! Inseridos: %d, Atualizados: %d", staging_schema, tabela_staging, schema, nome_tabela, inserted, updated)
        
        return inserted, updated

    finally:
        # Limpeza da tabela de staging
        try:
            with engine.begin() as conn:
                conn.execute(text(f'DROP TABLE IF EXISTS "{staging_schema}"."{tabela_staging}";'))
        except Exception as e:
            logger.warning("Falha ao remover tabela de staging '%s.%s': %s", staging_schema, tabela_staging, e)


# ==============================================================================
# MÓDULO 5: ORQUESTRADOR PRINCIPAL DO PIPELINE (ETL)
# ==============================================================================
def executar_pipeline_etl(modo_carga: Optional[str] = None) -> None:
    """
    Orquestra a execução completa do pipeline de ETL para os 20 recursos da API:
    1. Conexão com o PostgreSQL e validação do ambiente;
    2. Obtenção do Token OAuth 2.0;
    3. Extração paginada, transformação e carga (UPSERT / REPLACE) de cada endpoint;
    4. Emissão de relatório consolidado de auditoria.
    """
    modo = modo_carga or ETL_MODO_CARGA

    logger.info("=================================================================")
    logger.info("INICIANDO PROCESSO DE ETL: GESTÃO SEGURA -> POSTGRESQL (20 RECURSOS)")
    logger.info("MODO DE CARGA: %s | SCHEMA: %s", modo.upper(), DB_SCHEMA)
    logger.info("=================================================================")

    # 1. Validação de credenciais
    if not CLIENT_ID or not CLIENT_SECRET:
        logger.critical("Credenciais CLIENT_ID / CLIENT_SECRET não configuradas no ambiente!")
        sys.exit(1)

    # 2. Conexão com Banco de Dados
    try:
        engine = criar_conexao_postgresql(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            sslmode=DB_SSLMODE
        )
        with engine.connect() as conn:
            conn.execute(text("SELECT 1;"))
        logger.info("Conexão com o banco de dados PostgreSQL estabelecida com sucesso!")
    except Exception as e:
        logger.critical("Interrompendo pipeline devido a falha no banco de dados: %s", e)
        sys.exit(1)

    # 3. Autenticação na API (OAuth 2.0)
    try:
        token = obter_token_acesso(
            token_url=API_TOKEN_URL,
            client_id=CLIENT_ID,
            client_secret=CLIENT_SECRET
        )
    except Exception as e:
        logger.critical("Interrompendo pipeline devido a erro na autenticação da API: %s", e)
        sys.exit(1)

    # 4. Extração e Carga por Endpoint
    resumo_execucao = {}

    for chave, config in ENDPOINTS_CONFIG.items():
        endpoint = config["endpoint"]
        tabela = config["tabela"]
        descricao = config["descricao"]
        pk = config.get("primary_key", "-")

        logger.info("-----------------------------------------------------------------")
        logger.info("Processando: %s (PK: %s) -> Tabela: %s.%s", descricao, pk, DB_SCHEMA, tabela)

        try:
            # Extração paginada completa
            itens = extrair_dados_paginados(
                base_url=API_BASE_URL,
                endpoint=endpoint,
                token=token
            )

            # Transformação com Pandas e inclusão de dt_carga
            df = transformar_dados(itens)

            # Carga com suporte a UPSERT nativo via ON CONFLICT
            inserted, updated = carregar_dados_postgresql(
                df=df,
                nome_tabela=tabela,
                primary_key=pk,
                engine=engine,
                modo_carga=modo,
                schema=DB_SCHEMA
            )

            resumo_execucao[f"{DB_SCHEMA}.{tabela}"] = {
                "status": "SUCESSO",
                "registros_processados": len(df),
                "inseridos": inserted,
                "atualizados": updated
            }

        except Exception as e:
            logger.error("Falha no processamento do recurso '%s': %s", descricao, e)
            resumo_execucao[f"{DB_SCHEMA}.{tabela}"] = {
                "status": "FALHA / ADIADO",
                "erro": str(e),
                "registros_processados": 0
            }

    # 5. Relatório Final de Execução
    logger.info("=================================================================")
    logger.info("RESUMO DA EXECUÇÃO DO PIPELINE DE ETL (20 RECURSOS)")
    logger.info("=================================================================")
    for tab, dados in resumo_execucao.items():
        status = dados["status"]
        if status == "SUCESSO":
            regs = dados.get("registros_processados", 0)
            ins = dados.get("inseridos", 0)
            upd = dados.get("atualizados", 0)
            logger.info("Tabela: %-35s | Status: %-15s | Total: %s | Inseridos: %s | Atualizados: %s", tab, status, regs, ins, upd)
        else:
            logger.info("Tabela: %-35s | Status: %-15s | Erro: %s", tab, status, dados.get("erro", ""))
    logger.info("=================================================================")


# ==============================================================================
# PONTO DE ENTRADA (MAIN)
# ==============================================================================
if __name__ == "__main__":
    modo = sys.argv[1].lower() if len(sys.argv) > 1 and sys.argv[1].lower() in ("upsert", "replace") else ETL_MODO_CARGA
    executar_pipeline_etl(modo_carga=modo)
