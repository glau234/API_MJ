# Guia de Integração — API do Sistema Gestão Segura (SENASP/MJSP)

**Destinatário:** Secretaria de Segurança Pública do Distrito Federal (SSP/DF)  
**Emissor:** SENASP/MJSP — CPTI-Fundo  
**Versão:** 2.0 (Interface Ampliada — 20 Recursos Disponíveis)  
**Data:** Setembro de 2026  

---

## 1. O que é

API REST de **consulta (somente leitura)** aos dados operacionais, de planejamento, execução financeira, movimentação bancária e controle patrimonial do Fundo de Segurança Pública registrados no Sistema **Gestão Segura** (Ministério da Justiça e Segurança Pública).

A interface conta com **20 consultas ativas** em produção:

### 1.1. Planejamento (Consultas Originais)
| Recurso | O que retorna |
|---|---|
| `/api/v1/planos-aplicacao` | Planos de aplicação gerais (por área temática e ano) |
| `/api/v1/planos-acao` | Planos de ação — **somente a versão vigente** de cada um |
| `/api/v1/metas` | Metas dos planos de ação vigentes |
| `/api/v1/itens-contratacao` | Itens de contratação planejados (quantidades e valores) |

### 1.2. Execução do Empenho
| Recurso | O que retorna |
|---|---|
| `/api/v1/empenhos` | Empenhos emitidos (licitação, fornecedor e valores) |
| `/api/v1/empenhos-plano` | Vínculo empenho ↔ item planejado |
| `/api/v1/documentos` | Documentos de suporte (notas fiscais e comprovantes) |
| `/api/v1/empenho-documentos` | Vínculo empenho ↔ documento (fracionamento de despesa) |

### 1.3. Pagamentos Bancários (Origem TransfereGov)
| Recurso | O que retorna |
|---|---|
| `/api/v1/pagamentos` | Execuções e ordens bancárias (*volume expressivo*) |
| `/api/v1/documento-pagamentos` | Vínculo documento ↔ pagamento (fracionamento) |
| `/api/v1/pagamento-observacoes` | Observações registradas no histórico das execuções |

### 1.4. Contas do Fundo
| Recurso | O que retorna |
|---|---|
| `/api/v1/contas` | Contas bancárias vinculadas ao fundo e planos |
| `/api/v1/repasses` | Repasses recebidos do fundo |
| `/api/v1/rendimentos` | Rendimentos auferidos de aplicação financeira |
| `/api/v1/liberacoes` | Liberações de recurso formalizadas (Ofício / SEI) |
| `/api/v1/saldos-auditoria` | Histórico e evolução de saldos para auditoria |

### 1.5. Bens e Patrimônio
| Recurso | O que retorna |
|---|---|
| `/api/v1/bens-servicos` | Bens e serviços adquiridos vinculados a documento de suporte |
| `/api/v1/patrimonios` | Tombamento patrimonial dos bens (*volume expressivo*) |
| `/api/v1/itens-plan-exec` | Vínculo item planejado ↔ bem executado |

### 1.6. Tabela de Referência
| Recurso | O que retorna |
|---|---|
| `/api/v1/catalogo` | Catálogo nacional de materiais e serviços padronizados |

**Endereço base:** `https://apps.mj.gov.br/ws_20250508093400`

> ⚠️ **Filtro por UF:** A credencial institucional entregue à SSP/DF retorna exclusivamente dados do DF para 19 das 20 consultas.  
> A única exceção é a consulta **`/api/v1/catalogo`**, que por se tratar de tabela de referência nacional unificada, não possui o campo `sg_uf` em seu retorno.

---

## 2. Autenticação (OAuth 2.0 Client Credentials)

Não há qualquer alteração no mecanismo de acesso: valem a mesma credencial e o mesmo fluxo:

```bash
curl -s --user "SEU_CLIENT_ID:SEU_CLIENT_SECRET" \
  -H "Accept: application/json" \
  --data "grant_type=client_credentials" \
  https://apps.mj.gov.br/ws_20250508093400/oauth/token
```

Resposta esperada:
```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

---

## 3. Paginação e Volume de Dados

1. As respostas são paginadas em blocos de **25 registros** por padrão, orientadas pelos campos `hasMore`, `limit`, `offset` e `count`.
2. O parâmetro `?offset=N` avança na coleção:
   - Primeira página: `.../api/v1/pagamentos?offset=0`
   - Segunda página: `.../api/v1/pagamentos?offset=25`
3. Algumas consultas possuem **volume expressivo**, notadamente **`/pagamentos`** e **`/patrimonios`**. É obrigatório que os scripts de integração percorram o laço enquanto `hasMore` for `true`.

---

## 4. Encadeamento Relacional entre os Recursos

```
Planejamento:
  tb_planos_aplicacao (pk_gstb023)
     └─ tb_planos_acao (fk_gstb023 → pk_gstb041)
          └─ tb_metas (fk_gstb041 → pk_gstb042)
               └─ tb_itens_contratacao (fk_gstb042 → pk_gstb025)

Contas Bancárias:
  tb_contas (pk_gstb009)
     ├─ tb_repasses (fk_gstb009)
     ├─ tb_rendimentos (fk_gstb009)
     ├─ tb_liberacoes (fk_gstb009)
     └─ tb_saldos_auditoria (fk_gstb009)

Execução da Despesa & Documentos:
  tb_empenhos (pk_gstb014)
     ├─ tb_empenhos_plano (fk_gstb014 ↔ fk_gstb025)
     └─ tb_documentos (fk_gstb014 → pk_gstb016)
          └─ tb_empenho_documentos (fk_gstb014, fk_gstb016, fk_gstb025)

Pagamentos:
  tb_pagamentos (pk_gstb015) [fk_gstb016, fk_gstb009, fk_gstb014]
     ├─ tb_documento_pagamentos (fk_gstb015, fk_gstb016, fk_gstb025)
     └─ tb_pagamento_observacoes (fk_gstb015)

Bens e Patrimônio:
  tb_bens_servicos (pk_gstb017) [fk_gstb016, fk_gstb021]
     ├─ tb_patrimonios (fk_gstb017 → pk_gstb018)
     └─ tb_itens_plan_exec (fk_gstb017 ↔ fk_gstb025)
```

---

## 5. Exemplo de Integração em Python

```python
import requests

BASE = "https://apps.mj.gov.br/ws_20250508093400"
CLIENT_ID = "SEU_CLIENT_ID"
CLIENT_SECRET = "SEU_CLIENT_SECRET"

# 1) Obter Bearer Token
token_res = requests.post(
    f"{BASE}/oauth/token",
    auth=(CLIENT_ID, CLIENT_SECRET),
    headers={"Accept": "application/json"},
    data={"grant_type": "client_credentials"},
    timeout=30
).json()
headers = {"Authorization": f"Bearer {token_res['access_token']}", "Accept": "application/json"}

# 2) Extrair pagamentos do DF com paginação
pagamentos, offset = [], 0
while True:
    r = requests.get(f"{BASE}/api/v1/pagamentos", headers=headers, params={"offset": offset}, timeout=60).json()
    pagamentos += r.get("items", [])
    if not r.get("hasMore", False):
        break
    offset += r.get("limit", 25)

print(f"Total de pagamentos extraídos: {len(pagamentos)}")
```
