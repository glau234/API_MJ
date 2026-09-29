-- ==============================================================================
-- DDL DE CRIAÇÃO DO SCHEMA E TABELAS NO POSTGRESQL (BANCO: suag)
-- SCHEMA: API_MJ
-- Pipeline de Integração: API Gestão Segura (SENASP/MJSP)
-- Versão 2.0: 20 Tabelas Integradas (Planejamento, Financeiro, Patrimônio e Catálogo)
-- Autor: Gláucio Silveira e Silva - ASGED
-- Data: Setembro de 2026
-- ==============================================================================

-- 1. CRIAÇÃO DO SCHEMA E CONCESSÃO DE PRIVILÉGIOS (Executar como DBA / user_app / postgres)
CREATE SCHEMA IF NOT EXISTS "API_MJ";
GRANT USAGE, CREATE ON SCHEMA "API_MJ" TO user_glaucio;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "API_MJ" TO user_glaucio;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA "API_MJ" TO user_glaucio;
ALTER DEFAULT PRIVILEGES IN SCHEMA "API_MJ" GRANT ALL PRIVILEGES ON TABLES TO user_glaucio;


-- ==============================================================================
-- MÓDULO 1: PLANEJAMENTO (CONSULTAS ORIGINAIS)
-- ==============================================================================

-- 2. TABELA 1: tb_planos_aplicacao (Planos de Aplicação Gerais - Raiz)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_planos_aplicacao (
    pk_gstb023 BIGINT NOT NULL,
    sg_uf TEXT,
    ano_plan TEXT,
    sg_area_tematica TEXT,
    vl_plan_orig_custeio TEXT,
    vl_plan_orig_invest TEXT,
    vl_plan_supl_custeio TEXT,
    vl_plan_supl_invest TEXT,
    vl_plan_rend_custeio TEXT,
    vl_plan_rend_invest TEXT,
    tx_diagnostico TEXT,
    tx_justificativa TEXT,
    tx_meta_geral TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_planos_aplicacao PRIMARY KEY (pk_gstb023)
);

-- 3. TABELA 2: tb_planos_acao (Planos de Ação Vigentes)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_planos_acao (
    pk_gstb041 BIGINT NOT NULL,
    sg_uf TEXT,
    ano_plan TEXT,
    id_plano_acao_apagar_depois TEXT,
    codigo_plano_acao TEXT,
    data_inicio_vigencia_plano_acao TIMESTAMP WITHOUT TIME ZONE,
    data_fim_vigencia_plano_acao TIMESTAMP WITHOUT TIME ZONE,
    situacao_plano_acao TEXT,
    valor_repasse_emenda_plano_acao TEXT,
    valor_repasse_especifico_plano_acao TEXT,
    valor_repasse_voluntario_plano_acao TEXT,
    valor_total_repasse_plano_acao TEXT,
    valor_recursos_proprios_plano_acao TEXT,
    valor_outros_plano_acao TEXT,
    valor_rendimentos_aplicacao_plano_acao TEXT,
    valor_total_plano_acao TEXT,
    valor_total_investimento_plano_acao TEXT,
    valor_total_custeio_plano_acao TEXT,
    valor_saldo_disponivel_plano_acao TEXT,
    id_orgao_repassador_plano_acao TEXT,
    sigla_orgao_repassador_plano_acao TEXT,
    cnpj_orgao_repassador_plano_acao TEXT,
    nome_orgao_repassador_plano_acao TEXT,
    id_ente_repassador_plano_acao TEXT,
    cnpj_ente_repassador_plano_acao TEXT,
    nome_ente_repassador_plano_acao TEXT,
    uf_ente_repassador_plano_acao TEXT,
    nome_municipio_ente_repassador_plano_acao TEXT,
    codigo_ibge_municipio_ente_repassador_pa TEXT,
    id_ente_recebedor_plano_acao TEXT,
    cnpj_ente_recebedor_plano_acao TEXT,
    nome_ente_recebedor_plano_acao TEXT,
    uf_ente_recebedor_plano_acao TEXT,
    nome_municipio_ente_recebedor_plano_acao TEXT,
    codigo_ibge_municipio_ente_recebedor_pa TEXT,
    id_fundo_repassador_plano_acao TEXT,
    cnpj_fundo_repassador_plano_acao TEXT,
    nome_fundo_repassador_plano_acao TEXT,
    uf_fundo_repassador_plano_acao TEXT,
    municipio_fundo_repassador_plano_acao TEXT,
    codigo_ibge_fundo_repassador_plano_acao TEXT,
    id_fundo_recebedor_plano_acao TEXT,
    cnpj_fundo_recebedor_plano_acao TEXT,
    nome_fundo_recebedor_plano_acao TEXT,
    uf_fundo_recebedor_plano_acao TEXT,
    municipio_fundo_recebedor_plano_acao TEXT,
    codigo_ibge_fundo_recebedor_plano_acao TEXT,
    id_programa TEXT,
    fk_gstb023 BIGINT,
    vl_suplementar_investimento TEXT,
    vl_suplementar_custeio TEXT,
    tx_estrategia TEXT,
    tx_estrategia_i TEXT,
    tx_estrategia_ii TEXT,
    tx_estrategia_iii TEXT,
    tx_estrategia_iv TEXT,
    tx_indicador TEXT,
    nr_cpf_resp TEXT,
    no_resp TEXT,
    email_resp TEXT,
    no_cargo_resp TEXT,
    nr_tel_resp TEXT,
    nr_cpf_gestor TEXT,
    no_gestor TEXT,
    no_cargo_gestor TEXT,
    email_gestor TEXT,
    nr_tel_gestor TEXT,
    diagnostico_plano_acao TEXT,
    objetivos_plano_acao TEXT,
    tx_justificativa TEXT,
    id_plano_acao TEXT,
    hash_validacao TEXT,
    pk_plano_anterior TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_planos_acao PRIMARY KEY (pk_gstb041)
);
CREATE INDEX IF NOT EXISTS idx_planos_acao_fk_gstb023 ON "API_MJ".tb_planos_acao (fk_gstb023);

-- 4. TABELA 3: tb_metas (Metas dos Planos de Ação)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_metas (
    pk_gstb042 BIGINT NOT NULL,
    sg_uf TEXT,
    ano_plan TEXT,
    pk_gstb041 BIGINT,
    id_meta_plano_acao TEXT,
    numero_meta_plano_acao TEXT,
    nome_meta_plano_acao TEXT,
    valor_meta_plano_acao TEXT,
    versao_meta_plano_acao TEXT,
    sequencial_meta_plano_acao TEXT,
    id_plano_acao DOUBLE PRECISION,
    cl_periodicidade TEXT,
    vl_referencia_fonte_ano TEXT,
    no_carteira_pol_mjsp TEXT,
    no_meta_pesp TEXT,
    cl_status_meta TEXT,
    no_meta_pnsp TEXT,
    fk_gstb041 BIGINT,
    tx_formula_calculo TEXT,
    descricao_meta_plano_acao TEXT,
    cl_antigo TEXT,
    no_meta_plan_est_vcm TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_metas PRIMARY KEY (pk_gstb042)
);
CREATE INDEX IF NOT EXISTS idx_metas_fk_gstb041 ON "API_MJ".tb_metas (fk_gstb041);
CREATE INDEX IF NOT EXISTS idx_metas_pk_gstb041 ON "API_MJ".tb_metas (pk_gstb041);

-- 5. TABELA 4: tb_itens_contratacao (Itens de Contratação Planejados)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_itens_contratacao (
    pk_gstb025 BIGINT NOT NULL,
    sg_uf TEXT,
    ano_plan TEXT,
    pk_gstb041 BIGINT,
    pk_gstb042 BIGINT,
    fk_gstb024 TEXT,
    nr_meta TEXT,
    no_acao TEXT,
    fk_gstb021 BIGINT,
    tx_bem_servico TEXT,
    no_destinacao TEXT,
    nr_cod_senasp TEXT,
    no_instituicao TEXT,
    no_nd_apagar_depois TEXT,
    qtd_plan BIGINT,
    tp_un_medida TEXT,
    vl_plan_orig DOUBLE PRECISION,
    vl_plan_supl DOUBLE PRECISION,
    vl_plan_rend DOUBLE PRECISION,
    cl_status_item TEXT,
    no_item_migracao TEXT,
    fk_gstb042 BIGINT,
    nr_art TEXT,
    cl_antigo TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_itens_contratacao PRIMARY KEY (pk_gstb025)
);
CREATE INDEX IF NOT EXISTS idx_itens_contratacao_fk_gstb042 ON "API_MJ".tb_itens_contratacao (fk_gstb042);
CREATE INDEX IF NOT EXISTS idx_itens_contratacao_pk_gstb042 ON "API_MJ".tb_itens_contratacao (pk_gstb042);
CREATE INDEX IF NOT EXISTS idx_itens_contratacao_pk_gstb041 ON "API_MJ".tb_itens_contratacao (pk_gstb041);
CREATE INDEX IF NOT EXISTS idx_itens_contratacao_fk_gstb021 ON "API_MJ".tb_itens_contratacao (fk_gstb021);

-- ==============================================================================
-- MÓDULO 2: TABELAS DE REFERÊNCIA
-- ==============================================================================

-- 6. TABELA 5: tb_catalogo (Catálogo Nacional de Materiais e Serviços - Sem filtro de UF)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_catalogo (
    pk_gstb021 BIGINT NOT NULL,
    no_grupo TEXT,
    no_classe TEXT,
    no_bem_serv TEXT,
    no_nd TEXT,
    no_classe_cgtf TEXT,
    tp_bem_serv_dsusp TEXT,
    no_grupo_dsusp TEXT,
    no_classe_dsusp TEXT,
    nr_cod_senasp_dsusp TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_catalogo PRIMARY KEY (pk_gstb021)
);
CREATE INDEX IF NOT EXISTS idx_catalogo_nr_cod_senasp ON "API_MJ".tb_catalogo (nr_cod_senasp_dsusp);

-- ==============================================================================
-- MÓDULO 3: CONTAS DO FUNDO E GESTÃO FINANCEIRA
-- ==============================================================================

-- 7. TABELA 6: tb_contas (Contas Bancárias Vinculadas)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_contas (
    pk_gstb009 BIGINT NOT NULL,
    fk_gstb008 BIGINT,
    n_conta TEXT,
    sg_uf TEXT,
    n_ag TEXT,
    no_nd TEXT,
    vl_saldo_auditoria DOUBLE PRECISION,
    vl_bloqueado DOUBLE PRECISION,
    dt_atu_saldo TIMESTAMP WITHOUT TIME ZONE,
    id_plano_acao_dado_bancario BIGINT,
    id_agencia_conta TEXT,
    codigo_banco_plano_acao_dado_bancario TEXT,
    nome_banco_plano_acao_dado_bancario TEXT,
    numero_agencia_plano_acao_dado_bancario TEXT,
    dv_agencia_plano_acao_dado_bancario TEXT,
    numero_conta_plano_acao_dado_bancario TEXT,
    dv_conta_plano_acao_dado_bancario TEXT,
    situacao_conta_plano_acao_dado_bancario TEXT,
    data_abertura_conta_plano_acao_dado_bancario TIMESTAMP WITHOUT TIME ZONE,
    nome_programa_agil_conta_plano_acao_dado_bancario TEXT,
    id_plano_acao BIGINT,
    eixo TEXT,
    recurso TEXT,
    id_proc_fin TEXT,
    fk_gstb023 BIGINT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_contas PRIMARY KEY (pk_gstb009)
);
CREATE INDEX IF NOT EXISTS idx_contas_fk_gstb023 ON "API_MJ".tb_contas (fk_gstb023);
CREATE INDEX IF NOT EXISTS idx_contas_id_agencia_conta ON "API_MJ".tb_contas (id_agencia_conta);

-- 8. TABELA 7: tb_repasses (Repasses Recebidos do Fundo)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_repasses (
    pk_gstb028 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb009 BIGINT,
    tp_repasse TEXT,
    vl_repasse DOUBLE PRECISION,
    tp_obr TEXT,
    dt_repasse TIMESTAMP WITHOUT TIME ZONE,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_repasses PRIMARY KEY (pk_gstb028)
);
CREATE INDEX IF NOT EXISTS idx_repasses_fk_gstb009 ON "API_MJ".tb_repasses (fk_gstb009);

-- 9. TABELA 8: tb_rendimentos (Rendimentos de Aplicação Bancária)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_rendimentos (
    pk_gstb030 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb009 BIGINT,
    vl_rend DOUBLE PRECISION,
    dt_rend TIMESTAMP WITHOUT TIME ZONE,
    dt_atualizacao TIMESTAMP WITHOUT TIME ZONE,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_rendimentos PRIMARY KEY (pk_gstb030)
);
CREATE INDEX IF NOT EXISTS idx_rendimentos_fk_gstb009 ON "API_MJ".tb_rendimentos (fk_gstb009);

-- 10. TABELA 9: tb_liberacoes (Liberações de Recurso - Ofício / SEI)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_liberacoes (
    pk_gstb031 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb009 BIGINT,
    nr_oficio TEXT,
    vl_lib DOUBLE PRECISION,
    nr_sei TEXT,
    dt_lib TIMESTAMP WITHOUT TIME ZONE,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_liberacoes PRIMARY KEY (pk_gstb031)
);
CREATE INDEX IF NOT EXISTS idx_liberacoes_fk_gstb009 ON "API_MJ".tb_liberacoes (fk_gstb009);

-- 11. TABELA 10: tb_saldos_auditoria (Histórico e Evolução de Saldos)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_saldos_auditoria (
    pk_gstb035 BIGINT NOT NULL,
    sg_uf TEXT,
    dt_saldo TIMESTAMP WITHOUT TIME ZONE,
    vl_saldo DOUBLE PRECISION,
    fk_gstb009 BIGINT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_saldos_auditoria PRIMARY KEY (pk_gstb035)
);
CREATE INDEX IF NOT EXISTS idx_saldos_auditoria_fk_gstb009 ON "API_MJ".tb_saldos_auditoria (fk_gstb009);

-- ==============================================================================
-- MÓDULO 4: EXECUÇÃO DO EMPENHO
-- ==============================================================================

-- 12. TABELA 11: tb_empenhos (Empenhos, Licitações, Fornecedores e Valores)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_empenhos (
    pk_gstb014 BIGINT NOT NULL,
    sg_uf TEXT,
    nr_proc_compra TEXT,
    nr_licitacao TEXT,
    tp_licitacao TEXT,
    tx_base_legal TEXT,
    tx_parecer_jur TEXT,
    tx_declaracao_excl TEXT,
    no_orgao_contrat TEXT,
    nr_cnpj_orgao_contrat TEXT,
    no_fornecedor TEXT,
    nr_cnpj_fornecedor TEXT,
    dt_empenho TIMESTAMP WITHOUT TIME ZONE,
    vl_empenho DOUBLE PRECISION,
    nr_empenho TEXT,
    tx_edital_chamamento TEXT,
    tx_declaracao_inex TEXT,
    ic_lei_antiga TEXT,
    tp_empenho TEXT,
    no_nd TEXT,
    id_geral TEXT,
    cl_compra_susp TEXT,
    cl_check_upload TEXT,
    cl_adesao_ata TEXT,
    cl_ata TEXT,
    obs_empenho TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_empenhos PRIMARY KEY (pk_gstb014)
);
CREATE INDEX IF NOT EXISTS idx_empenhos_nr_empenho ON "API_MJ".tb_empenhos (nr_empenho);
CREATE INDEX IF NOT EXISTS idx_empenhos_nr_cnpj_fornecedor ON "API_MJ".tb_empenhos (nr_cnpj_fornecedor);

-- 13. TABELA 12: tb_empenhos_plano (Vínculo Empenho ↔ Item Planejado)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_empenhos_plano (
    pk_gstb033 BIGINT NOT NULL,
    sg_uf TEXT,
    ano_plan TEXT,
    fk_gstb014 BIGINT,
    fk_gstb023 BIGINT,
    vl_planejado DOUBLE PRECISION,
    fk_gstb025 BIGINT,
    tp_vinculo TEXT,
    tx_obs TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_empenhos_plano PRIMARY KEY (pk_gstb033)
);
CREATE INDEX IF NOT EXISTS idx_empenhos_plano_fk_gstb014 ON "API_MJ".tb_empenhos_plano (fk_gstb014);
CREATE INDEX IF NOT EXISTS idx_empenhos_plano_fk_gstb023 ON "API_MJ".tb_empenhos_plano (fk_gstb023);
CREATE INDEX IF NOT EXISTS idx_empenhos_plano_fk_gstb025 ON "API_MJ".tb_empenhos_plano (fk_gstb025);

-- 14. TABELA 13: tb_documentos (Documentos de Suporte / Notas Fiscais e Comprovantes)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_documentos (
    pk_gstb016 BIGINT NOT NULL,
    sg_uf TEXT,
    tp_doc_suporte TEXT,
    nr_doc_suporte TEXT,
    dt_doc_suporte TIMESTAMP WITHOUT TIME ZONE,
    nr_chave_doc_suporte TEXT,
    vl_total_doc DOUBLE PRECISION,
    fk_gstb014 BIGINT,
    id_geral TEXT,
    tx_nota TEXT,
    fl_totalmente_pago TEXT,
    tx_just_pagto_parcial TEXT,
    obs_doc_suporte TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_documentos PRIMARY KEY (pk_gstb016)
);
CREATE INDEX IF NOT EXISTS idx_documentos_fk_gstb014 ON "API_MJ".tb_documentos (fk_gstb014);
CREATE INDEX IF NOT EXISTS idx_documentos_nr_doc_suporte ON "API_MJ".tb_documentos (nr_doc_suporte);

-- 15. TABELA 14: tb_empenho_documentos (Vínculo Empenho ↔ Documento / Fracionamento)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_empenho_documentos (
    pk_gstb056 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb014 BIGINT,
    fk_gstb016 BIGINT,
    vl_fracionado DOUBLE PRECISION,
    cl_origem TEXT,
    dt_cadastro TIMESTAMP WITHOUT TIME ZONE,
    no_user TEXT,
    tx_obs TEXT,
    fk_gstb025 BIGINT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_empenho_documentos PRIMARY KEY (pk_gstb056)
);
CREATE INDEX IF NOT EXISTS idx_empenho_documentos_fk_gstb014 ON "API_MJ".tb_empenho_documentos (fk_gstb014);
CREATE INDEX IF NOT EXISTS idx_empenho_documentos_fk_gstb016 ON "API_MJ".tb_empenho_documentos (fk_gstb016);
CREATE INDEX IF NOT EXISTS idx_empenho_documentos_fk_gstb025 ON "API_MJ".tb_empenho_documentos (fk_gstb025);

-- ==============================================================================
-- MÓDULO 5: PAGAMENTOS BANCÁRIOS (TRANSFEREGOV)
-- ==============================================================================

-- 16. TABELA 15: tb_pagamentos (Execuções Bancárias / TransfereGov - Volume Expressivo)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_pagamentos (
    pk_gstb015 BIGINT NOT NULL,
    sg_uf TEXT,
    dt_pag_banc TIMESTAMP WITHOUT TIME ZONE,
    vl_pag_banc DOUBLE PRECISION,
    fk_gstb016 BIGINT,
    id_transferegov TEXT,
    fk_gstb009 BIGINT,
    fk_gstb014 BIGINT,
    id_programa BIGINT,
    cnpj_ente_solicitante_gestao_financeira TEXT,
    codigo_agencia_beneficiario_subtransacao_gestao_financeira TEXT,
    codigo_agencia_favorecido_gestao_financeira TEXT,
    codigo_agencia_gestao_financeira TEXT,
    codigo_banco_beneficiario_subtransacao_gestao_financeira TEXT,
    codigo_banco_favorecido_gestao_financeira TEXT,
    codigo_banco_gestao_financeira TEXT,
    codigo_conta_beneficiario_subtransacao_gestao_financeira TEXT,
    codigo_conta_favorecido_gestao_financeira TEXT,
    codigo_conta_gestao_financeira TEXT,
    codigo_programa_agil_ente_solicitante_gestao_financeira TEXT,
    data_lancamento_gestao_financeira TIMESTAMP WITHOUT TIME ZONE,
    data_pagamento_subtransacao_gestao_financeira TIMESTAMP WITHOUT TIME ZONE,
    descricao_gestao_financeira TEXT,
    descricao_origem_solicitacao_gestao_financeira TEXT,
    descricao_situacao_pagamento_subtransacao_gestao_financeira TEXT,
    descricao_subtransacao_gestao_financeira TEXT,
    descricao_tipo_favorecido_gestao_financeira TEXT,
    descricao_tipo_operacao_gestao_financeira TEXT,
    descricao_tipo_pessoa_beneficiario_subtransacao_gestao_financei TEXT,
    doc_favorecido_gestao_financeira_mask TEXT,
    dv_agencia_favorecido_gestao_financeira TEXT,
    dv_agencia_gestao_financeira TEXT,
    dv_conta_favorecido_gestao_financeira TEXT,
    dv_conta_gestao_financeira TEXT,
    estado_subtransacao_gestao_financeira TEXT,
    id_agencia_conta TEXT,
    id_lancamento_gestao_financeira BIGINT,
    id_plano_acao BIGINT,
    id_subtransacao_gestao_financeira BIGINT,
    nome_beneficiario_subtransacao_gestao_financeira TEXT,
    nome_ente_solicitante_gestao_financeira TEXT,
    nome_favorecido_gestao_financeira TEXT,
    nome_personalizado_ente_solicitante_gestao_financeira TEXT,
    numero_documento_beneficiario_subtransacao_gestao_financeira_ma TEXT,
    numero_ordem_gestao_financeira TEXT,
    numero_referencia_unica_gestao_financeira TEXT,
    origem_solicitacao_gestao_financeira TEXT,
    quantidade_subtransacoes_lancamento_gestao_financeira BIGINT,
    situacao_pagamento_subtransacao_gestao_financeira TEXT,
    tipo_favorecido_gestao_financeira TEXT,
    tipo_operacao_gestao_financeira TEXT,
    tipo_pessoa_beneficiario_subtransacao_gestao_financeira TEXT,
    valor_lancamento_gestao_financeira DOUBLE PRECISION,
    valor_subtransacao_gestao_financeira DOUBLE PRECISION,
    tx_obs TEXT,
    sn_dispensa_conferencia TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_pagamentos PRIMARY KEY (pk_gstb015)
);
CREATE INDEX IF NOT EXISTS idx_pagamentos_fk_gstb016 ON "API_MJ".tb_pagamentos (fk_gstb016);
CREATE INDEX IF NOT EXISTS idx_pagamentos_fk_gstb009 ON "API_MJ".tb_pagamentos (fk_gstb009);
CREATE INDEX IF NOT EXISTS idx_pagamentos_fk_gstb014 ON "API_MJ".tb_pagamentos (fk_gstb014);
CREATE INDEX IF NOT EXISTS idx_pagamentos_id_transferegov ON "API_MJ".tb_pagamentos (id_transferegov);

-- 17. TABELA 16: tb_documento_pagamentos (Vínculo Documento ↔ Pagamento / Fracionamento)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_documento_pagamentos (
    pk_gstb054 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb015 BIGINT,
    fk_gstb016 BIGINT,
    vl_pag_fracionado DOUBLE PRECISION,
    dt_cadastro TIMESTAMP WITHOUT TIME ZONE,
    no_user_cad TEXT,
    tp_vinculo TEXT,
    fk_gstb025 BIGINT,
    tx_obs TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_documento_pagamentos PRIMARY KEY (pk_gstb054)
);
CREATE INDEX IF NOT EXISTS idx_documento_pagamentos_fk_gstb015 ON "API_MJ".tb_documento_pagamentos (fk_gstb015);
CREATE INDEX IF NOT EXISTS idx_documento_pagamentos_fk_gstb016 ON "API_MJ".tb_documento_pagamentos (fk_gstb016);
CREATE INDEX IF NOT EXISTS idx_documento_pagamentos_fk_gstb025 ON "API_MJ".tb_documento_pagamentos (fk_gstb025);

-- 18. TABELA 17: tb_pagamento_observacoes (Observações das Execuções de Pagamento)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_pagamento_observacoes (
    pk_gstb036 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb015 BIGINT,
    dt_obs TIMESTAMP WITHOUT TIME ZONE,
    user_obs TEXT,
    tx_obs TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_pagamento_observacoes PRIMARY KEY (pk_gstb036)
);
CREATE INDEX IF NOT EXISTS idx_pagamento_observacoes_fk_gstb015 ON "API_MJ".tb_pagamento_observacoes (fk_gstb015);

-- ==============================================================================
-- MÓDULO 6: BENS E PATRIMÔNIO
-- ==============================================================================

-- 19. TABELA 18: tb_bens_servicos (Bens e Serviços Adquiridos Vinculados a Documentos)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_bens_servicos (
    pk_gstb017 BIGINT NOT NULL,
    sg_uf TEXT,
    no_bem_servico TEXT,
    vl_unitario DOUBLE PRECISION,
    no_orgao TEXT,
    qtd_item DOUBLE PRECISION,
    fk_gstb021 BIGINT,
    fk_gstb015 BIGINT,
    no_titulacao TEXT,
    fk_gstb042 BIGINT,
    id_geral TEXT,
    tx_relatorio TEXT,
    fk_gstb016 BIGINT,
    fk_gstb025 BIGINT,
    tx_obs TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_bens_servicos PRIMARY KEY (pk_gstb017)
);
CREATE INDEX IF NOT EXISTS idx_bens_servicos_fk_gstb021 ON "API_MJ".tb_bens_servicos (fk_gstb021);
CREATE INDEX IF NOT EXISTS idx_bens_servicos_fk_gstb016 ON "API_MJ".tb_bens_servicos (fk_gstb016);
CREATE INDEX IF NOT EXISTS idx_bens_servicos_fk_gstb025 ON "API_MJ".tb_bens_servicos (fk_gstb025);
CREATE INDEX IF NOT EXISTS idx_bens_servicos_fk_gstb042 ON "API_MJ".tb_bens_servicos (fk_gstb042);
CREATE INDEX IF NOT EXISTS idx_bens_servicos_fk_gstb015 ON "API_MJ".tb_bens_servicos (fk_gstb015);

-- 20. TABELA 19: tb_patrimonios (Tombamento Patrimonial - Volume Expressivo)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_patrimonios (
    pk_gstb018 BIGINT NOT NULL,
    sg_uf TEXT,
    fk_gstb017 BIGINT,
    nr_patrimonio TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_patrimonios PRIMARY KEY (pk_gstb018)
);
CREATE INDEX IF NOT EXISTS idx_patrimonios_fk_gstb017 ON "API_MJ".tb_patrimonios (fk_gstb017);
CREATE INDEX IF NOT EXISTS idx_patrimonios_nr_patrimonio ON "API_MJ".tb_patrimonios (nr_patrimonio);

-- 21. TABELA 20: tb_itens_plan_exec (Vínculo Item Planejado ↔ Bem Executado)
CREATE TABLE IF NOT EXISTS "API_MJ".tb_itens_plan_exec (
    pk_gstb061 BIGINT NOT NULL,
    sg_uf TEXT,
    ano_plan TEXT,
    fk_gstb025 BIGINT,
    fk_gstb017 BIGINT,
    vl_fracionado DOUBLE PRECISION,
    dt_cadastro TIMESTAMP WITHOUT TIME ZONE,
    no_user TEXT,
    tp_vinculo TEXT,
    tx_obs TEXT,
    dt_carga TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_tb_itens_plan_exec PRIMARY KEY (pk_gstb061)
);
CREATE INDEX IF NOT EXISTS idx_itens_plan_exec_fk_gstb025 ON "API_MJ".tb_itens_plan_exec (fk_gstb025);
CREATE INDEX IF NOT EXISTS idx_itens_plan_exec_fk_gstb017 ON "API_MJ".tb_itens_plan_exec (fk_gstb017);
