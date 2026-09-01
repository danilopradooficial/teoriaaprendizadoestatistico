<div align="center">

# Atividade 02A - Análise exploratória ampla (completa)

**Teoria do Aprendizado Estatístico · Ciência de Dados · Fatec Rubens Lara**

Estatística descritiva do Estatístico Aquaviário (ANTAQ, 2021-2025):
qualidade, univariada, bivariada, tempo, hierarquia e o que isso proíbe
na hora de estimar \(f\).

![R](https://img.shields.io/badge/R-base-276DC3?style=flat&logo=r&logoColor=white)
![Status](https://img.shields.io/badge/status-entregue-brightgreen)
![Aula](https://img.shields.io/badge/aula-03-lightgrey)

</div>

---

## Papel deste arquivo no funil

Esta é a versão **ampla completa**: olhamos o banco ANTAQ de vários ângulos
(inventário, qualidade, carga, geografia, Santos etc.) para descobrir onde
valia a pena aprofundar. O que saltou aos olhos foram os **tempos do navio**
(espera, atracação, operação e desatracação).

A entrega enxuta pedida pelo professor está em
[analise_exploratoria_segmentada_entrega.md](analise_exploratoria_segmentada_entrega.md).
Este arquivo fica como memória da exploração larga.

---

## Sobre a atividade

Segunda entrega sobre o banco: cumprir o laboratório da **Aula 03**
(EDA + variáveis aleatórias), com a régua da Aula 02 (o tipo da variável
decide o resumo e o gráfico).

Antes de qualquer modelo (\(Y = f(X)+\varepsilon\)):

1. Qual é a **unidade amostral** e o \(n\)?
2. As colunas estão no **tipo** certo?
3. Onde estão **faltantes, sentinelas e caudas**?
4. O que é típico (mediana) versus o que é extremo (média, P99, IQR)?
5. O que **não** é i.i.d. (escala, berço, porto, mês)?
6. Que \(Y\) e que \(X\) são defensáveis **sem vazamento**?
7. Qual a **forma** da distribuição de uma contínua - e qual distribuição
   teórica ela lembra (Normal, Exponencial, …)?

> **Meta:** cumprir o pedido do PDF - 2 gráficos quadrados comentados +
> uma frase sobre a forma da distribuição - e, de quebra, deixar claro o
> que essa EDA **proíbe** na hora de estimar \(f\).

---

## Material de referência

- [Aula 03 - Análise Exploratória e Variáveis Aleatórias](../../MateriaisAulas/Aula%2003%20-%20Análise%20Exploratória%20e%20Variáveis%20Aleatórias.PDF)
- [Aula 02 - Dados e Variáveis](../../MateriaisAulas/Aula%2002%20-%20Dados%20e%20Variáveis.PDF)
- [Dicionário de variáveis](../atividade_01/dicionario_variaveis_amplo_completo.md)
- [README da disciplina](../../readme.md)

Números calculados sobre os microdados **locais** (não versionados), com
`sep = ";"`, `dec = ","`.

---

Documento de **estatística descritiva** do banco escolhido para o trabalho da disciplina. Cumpre a Aula 03 (EDA no R + variáveis aleatórias) com a régua da Aula 02 (tipo decide o resumo e o gráfico).

Os números abaixo foram calculados sobre **todos** os microdados locais (não sobre amostra), com `sep = ";"`, `dec = ","`. Totais de peso usam `FlagMCOperacaoCarga == 1`, salvo indicação. Identidades de tempo: `TAtracado = T2+T3+T4` e `TEstadia = T1+…+T4` (erro mediano da ordem de \(10^{-13}\) h).

Notação: padrão brasileiro (ponto de milhar, vírgula decimal). Assim, **1.212 milhões de t** = 1,21 bilhão de toneladas.

Companheiro: [dicionário de variáveis](../atividade_01/dicionario_variaveis_amplo_completo.md) (tipos, joins e flags). Caminhos de dados neste texto são relativos à **raiz do repositório**. O banco em `DatasetMovimentacaoPortuaria/` é local e não entra no GitHub.

### Checklist do laboratório (Aula 03)

O PDF pede, no banco do trabalho:

| Pedido do PDF | Neste arquivo |
|---|---|
| EDA de **uma** quantitativa: `summary`, `sd(..., na.rm = TRUE)`, `hist(..., prob = TRUE)`, `boxplot` com `par(pty = "s")` | Seções 5 e 8.1 |
| Relação entre **duas** variáveis (`plot` ou `boxplot(y ~ grupo)`) | Seção 8.2 |
| Sobrepor `dnorm` a uma contínua | Seção 8.1 |
| Contar faltantes: `colSums(is.na(...))` | Seção 3 (+ trecho em 8.6) |
| **Entregar:** 2 gráficos quadrados comentados | Seções 8.1 e 8.2 (PNGs) |
| **Entregar:** uma frase sobre a forma (simétrica? assimétrica? qual distribuição lembra?) | Seção 8.4 |

O restante do `.md` (inventário, hierarquia, implicações para \(f\)) é **extra** para o semestre; não substitui os itens acima.

---

## 1. Perguntas que a EDA responde

Antes de qualquer modelo (Aula 01: \(Y = f(X)+\varepsilon\)):

1. Qual é a **unidade amostral** e o \(n\)?
2. As colunas estão no **tipo** certo (Aula 02)?
3. Onde estão **faltantes, sentinelas e caudas**?
4. O que é típico (mediana) versus o que é extremo (média, P99, IQR)?
5. O que **não** é i.i.d. (escala, berço, porto, mês)?
6. Que \(Y\) e que \(X\) são defensáveis **sem vazamento**?
7. Qual a **forma** de uma contínua - e qual distribuição teórica ela lembra?

Esta EDA não escolhe o modelo; ela **proíbe** escolhas ingênuas.

---

## 2. Inventário e crescimento

| Tabela | 2021 | 2022 | 2023 | 2024 | 2025 | Total |
|---|---:|---:|---:|---:|---:|---:|
| Atracação / Tempos | 79.238 | 85.092 | 93.918 | 106.834 | 116.222 | **481.304** |
| Carga | 2.348.365 | 2.280.017 | 2.200.645 | 2.439.611 | 2.464.613 | **11.733.251** |
| Carga (flag MC = 1) | 2.240.273 | 2.143.012 | 2.077.131 | 2.267.226 | 2.291.343 | **11.018.985** |
| Carga conteinerizada | 13.065.789 | 13.156.352 | 13.341.330 | 14.908.576 | 13.758.093 | **68.230.140** |
| Hidrovia | 578.583 | 581.022 | 504.487 | 735.981 | 784.755 | 3.184.828 |
| Região hidrográfica | 358.503 | 370.162 | 305.301 | 456.269 | 480.967 | 1.971.202 |
| Rio | 403.003 | 414.125 | 345.616 | 491.101 | 513.745 | 2.167.590 |
| Áreas (só 2023+) | - | - | 2.084.579 | 2.275.115 | 2.300.783 | 6.660.477 |
| Taxa de ocupação | 313.346 | 322.028 | 323.780 | 327.497 | 327.040 | 1.613.691 |
| Paralisação | 104.079 | 106.569 | 123.567 | 225.160 | 228.077 | 787.452 |

Escalas: **+46,7%** de 2021 a 2025. Não interprete isso só como “o Brasil atracou 47% a mais”: entra cobertura cadastral (novos TUP), interior amazônico e mudança de mix (mais escalas curtas). O peso com flag MC cresce de **1,21 bilhão de t** (2021) para **1,40 bilhão de t** (2025), +16% - bem menos que a contagem de escalas. **Frequência e tonelagem contam histórias diferentes.**

Cobertura cadastral (dimensões, estáticas):

| Dimensão | \(n\) | Notas |
|---|---:|---|
| Mercadoria (SH4 / equipamento) | 1.403 | 103 capítulos SH2; 159 nomes simplificados ANTAQ |
| Mercadoria conteinerizada | 1.296 | 102 grupos |
| Instalações de origem | 3.553 | 197 países |
| Instalações de destino | 5.270 | 202 países |

`IDAtracacao` não se repete no quinquênio (481.304 IDs = 481.304 linhas). Tempos está em **1:1** com atracação. **82,3%** das escalas têm pelo menos uma partida em `Carga` (396.007 IDs). As demais são, em grande parte, apoio, passageiro, marinha e reparo.

---

## 3. Qualidade dos dados

### 3.1 Linhas ocos na atracação

Cerca de **475 escalas (0,10%)** vêm com berço, porto, coordenadas, tipo de operação e navegação vazios. São ruído de cadastro. Descarte-as no ETL (`is.na(CDTUP)` ou `is.na(\`Tipo de Operação\`)`).

### 3.2 Faltantes na atracação (quinquênio)

| Campo | Faltantes | % | Leitura |
|---|---:|---:|---|
| Apelido da instalação | 327.659 | 68,1 | opcional; não use como preditor |
| Região hidrográfica | ~54% (marítimo vazio) | estrutural | `NA` ≠ erro no porto oceânico |
| Nº do IMO | ~50% | estrutural | interior/apoio não têm IMO |
| Nº da Capitania | ~38% | complementar ao IMO | |
| Data início/término de operação | ~27,6 mil | 5,7 | T2/T3/T4 ficam `NA` |
| Coordenadas / UF / município | 475 | 0,1 | as linhas ocos |

**IMO e Capitania são identificadores**, não quantitativas (Aula 02). Percentual de preenchimento descreve *tipo de frota*, não “qualidade da variável contínua”.

### 3.3 Tempos: faltantes e identidades

No quinquênio, entre quem tem o campo parseável:

| Tempo | \(n\) válido | % NA (sobre 481.304) | Mediana (h) | Média (h) | P95 (h) | Máximo (h) |
|---|---:|---:|---:|---:|---:|---:|
| T1 espera atracação | 433.258 | ~10,0 | 1,08 | 41,9 | 206 | 18.251 |
| T2 espera início op. | 439.564 | ~8,7 | 0,52 | 3,31 | 10,3 | 2.142 |
| T3 operação | 443.962 | ~7,8 | 7,48 | 20,4 | 86,2 | 2.377 |
| T4 espera desatracação | 444.511 | ~7,6 | 1,12 | 3,26 | 12,2 | 721 |
| TA atracado | 471.337 | ~2,1 | 12,3 | 28,7 | 107 | 4.634 |
| TE estadia | 469.164 | ~2,5 | 22,0 | 69,6 | 285 | 18.869 |

Não há negativos. Não há zeros exatos (o mínimo observado é ~1 minuto = 0,0167 h - piso de medição).

Identidades TA e TE: **medianas do erro absoluto ≈ 0**. O dicionário ANTAQ está operacionalmente correto neste dump.

T3 faltante por ano (sobre o \(n\) do ano): 6,2% (2021), 7,2% (2022), 7,1% (2023), **9,8% (2024)**, 8,0% (2025). Não é MCAR trivial: concentra-se em tipos de operação sem carga/descarga. **Não impute T3 com a média global.**

### 3.4 Carga: sentinelas que copiam a flag

`Origem` e `Destino` faltantes: **714.266** linhas - **igual** a `FlagMCOperacaoCarga == 0`. Não é falha aleatória: partidas fora da apuração oficial vêm sem O/D. Filtrar `FlagMCOperacaoCarga == 1` remove esse `NA` de uma vez.

`Tipo Navegação` traz o rótulo oficial **`Não Indentificado`** (erro de grafia, 714.266 linhas - de novo o bloco flag = 0).

`Carga Geral Acondicionamento` vazio nas naturezas a granel (~433 mil): `NA` estrutural.

### 3.5 Painel quebrado: áreas

`CargaAreas` **não existe** em 2021-2022. Em 2023-2025, CNPJ/empresa faltam em 1-2% (embarque direto). Qualquer modelo de operador com CNPJ ou corta o recorte, ou trata 2021-2022 como `NA` estrutural.

### 3.6 Quebra de preenchimento nas paralisações

Eventos: 104 mil (2021) → 107 mil (2022) → 124 mil (2023) → **225 mil (2024)** → 228 mil (2025). O salto 2023-2024 coincide com a explosão do motivo **“Aguardando carga”** (60,9 mil em 2024). Isso é mudança de **preenchimento**, não necessariamente o dobro de problemas operacionais. Não use a série de paralisações como indicador bruto de “piora”.

### 3.7 Vírgula decimal

No arquivo, quantitativas usam vírgula (`37,95`). Em R: `fread(..., dec = ",")` (ou `read.table(..., dec = ",")`). Sem `dec = ","`, o R lê a coluna como texto, `as.numeric` vira `NA` e a mediana de T3 vira artefato. Sintoma típico: \(n\) de T3 da ordem de 2 mil em vez de ~70-80 mil no ano. **Cheque o \(n\) do `summary` contra o número de linhas.**

---

## 4. Univariada - qualitativas (barras / `table`)

### 4.1 Tipo de operação da escala

| Tipo | Escalas | % |
|---|---:|---:|
| Movimentação da Carga | 359.172 | 74,6 |
| Apoio | 86.790 | 18,0 |
| Passageiro | 25.654 | 5,3 |
| Abastecimento | 4.651 | 1,0 |
| Reparo/Manutenção | 3.277 | 0,7 |
| Marinha | 733 | 0,2 |
| Misto | 430 | 0,1 |
| Retirada de Resíduos | 122 | 0,03 |
| `<NA>` | 475 | 0,1 |

`FlagMCOperacaoAtracacao` vale **1 em 100%** deste dump: **não discrimina**. O filtro operacional de “escala de carga” é `Tipo de Operação == "Movimentação da Carga"`, não a flag.

Gráfico: `barplot(table(...))` ou `ggplot` de colunas. Não há ordem natural (nominal).

### 4.2 Navegação da escala (contagem ≠ tonelagem)

| Navegação | Escalas | % escalas |
|---|---:|---:|
| Interior | 234.733 | 48,8 |
| Longo Curso | 108.785 | 22,6 |
| Cabotagem | 80.025 | 16,6 |
| Apoio Marítimo | 32.219 | 6,7 |
| Apoio Portuário | 25.067 | 5,2 |

Quase **metade das escalas é interior**. Isso é o pulso amazônico (muitas manobras de empurradores/barcaças). Em **toneladas** (carga, flag MC) a ordem se inverte:

| Navegação | Peso (milhões de t) | % peso |
|---|---:|---:|
| Longo Curso | 4.594 | 71,0 |
| Cabotagem | 1.456 | 22,5 |
| Interior | 410 | 6,3 |
| Apoio portuário / marítimo | ~14 | 0,2 |

**Não use a moda da escala como proxy de comércio exterior.**

### 4.3 Geografia das escalas

| Região | Escalas | % |
|---|---:|---:|
| Norte | 209.030 | 43,4 |
| Sudeste | 131.827 | 27,4 |
| Sul | 63.497 | 13,2 |
| Nordeste | 60.485 | 12,6 |
| Centro-Oeste | 15.986 | 3,3 |

UF (top): PA 119.172, RJ 80.531, AM 57.369, RS 37.586, SP 37.252, RO 29.735.

Autoridade: **Terminal Autorizado 290.459 (60,3%)** vs Porto Organizado 190.845 (39,7%). Instalação em rio: Sim 230.925 (48,0%).

Complexos com mais escalas (não necessariamente mais toneladas): Vila do Conde-Belém, Manaus, Rio de Janeiro-Niterói, São João da Barra (Açu), Santos, Porto Velho, Santarém, Itaituba.

Santos **não** lidera em número de escalas; lidera em perfil de longo curso e contêiner. Um ranking por `n` sem peso enviesa o Norte.

### 4.4 Mês (`ordered`)

`Mes` é **ordinal**. Frequência relativamente plana, com leve vale em janeiro (35.171) e pico em julho (43.381). Safra de grãos e regime hidrológico amazônico pedem mês como fator, não como inteiro 1-12 em `lm` sem dummies.

### 4.5 Natureza da carga: linhas versus toneladas

**Linhas** (partidas, flag MC ≈ todas as naturezas no arquivo):

| Natureza | Partidas | % partidas |
|---|---:|---:|
| Carga Conteinerizada | 9.681.748 | 82,5 |
| Carga Geral | 1.618.157 | 13,8 |
| Granel Sólido | 294.240 | 2,5 |
| Granel Líquido e Gasoso | 139.106 | 1,2 |

**Toneladas** (flag MC):

| Natureza | Peso (milhões de t) | % peso |
|---|---:|---:|
| Granel Sólido | 3.856 | 59,6 |
| Granel Líquido e Gasoso | 1.595 | 24,6 |
| Carga Conteinerizada | 707 | 10,9 |
| Carga Geral | 317 | 4,9 |

Uma partida de minério pesa dezenas de milhares de toneladas; uma partida de contêiner, da ordem de 11 t (mediana 2024). **Classificar natureza na linha é fácil e desbalanceado; regressão de peso na linha é dominada por granel.**

Contêiner: 5,20 milhões cheios vs 4,46 milhões vazios (linhas com estado preenchido). Tamanho: 40' (7,13 M) >> 20' (2,55 M). TEU da partida (2024, MC): mediana **2** (um 40'), média 6,1, P99 120, máximo 5.016 (escala agregada num único `IDCarga` atípico - investigar antes de winsorizar).

### 4.6 Sentido

Partidas: Desembarcados 5,96 M; Embarcados 5,09 M; Não Informado 0,69 M.  
**Peso (MC):** Embarcados **4,33 bilhões de t** vs Desembarcados **2,15 bilhões de t**. O Brasil deste banco é **exportador em toneladas** (minério, soja) e mais equilibrado em número de BL/contêiner.

### 4.7 Armador

Nacionalidade: 1 (brasileira) 351.322 (73,0%); 2 (estrangeira) 128.871 (26,8%); 0 636; NA 475. O `0` não está no dicionário oficial - recodificar como nível próprio, **não** como zero numérico.

---

## 5. Univariada - quantitativas (histograma / quantis)

A Aula 02: média e histograma só depois de tipar como contínua. Aqui **média ≠ mediana** em todos os tempos e no peso: assimetria à direita.

### 5.1 Tempos (horas), todas as escalas

Interpretação: a **mediana** é o navio típico (T3 ≈ 7,5 h; estadia ≈ 22 h). A **média** de T1 (42 h) é puxada pela fila. P95 de T1 (206 h ≈ 8,6 dias) é o regime de congestionamento. Máximos de milhares de horas são escalas paradas / cadastro - candidatos a winsorização no P99 (525 h em T1) se o alvo for predição, **depois** de olhar o tipo de operação.

Só **Movimentação da Carga**:

| Tempo | \(n\) | Mediana (h) | Média (h) | P95 (h) |
|---|---:|---:|---:|---:|
| T1 | 333.433 | 2,00 | 46,8 | 247 |
| T2 | 346.483 | 0,95 | 4,02 | 12,3 |
| T3 | 353.649 | 8,67 | 22,3 | 91,9 |
| T4 | 351.872 | 1,60 | 3,47 | 13,0 |
| TA | 353.816 | 15,0 | 31,1 | 112 |
| TE | 351.717 | 30,0 | 78,1 | 323 |

T3 mediano **cai** ao longo dos anos (8,73 h em 2021 → 6,75 h em 2025, todas as escalas). Parte disso é mix (mais interior curto), não só “produtividade”. Controle por natureza e complexo antes de celebrar ganho de prancha.

### 5.2 Peso da partida (2024, flag MC)

| Estatística | t |
|---|---:|
| \(n\) | 2.267.226 |
| Mínimo | 0,001 |
| P5 | 2,12 |
| Q1 | 3,8 |
| Mediana | **11** |
| Q3 | 30 |
| P95 | 1.036 |
| P99 | 7.529 |
| Máximo | 500.570 |
| Média | 585 |

Mediana 11 t = mundo do contêiner. Média 585 t = mundo do granel. Modelo linear em \(Y =\) peso **na linha** sem `log1p` e sem estratificar natureza é um modelo do P99.

Totais anuais (flag MC), milhões de toneladas:

| Ano | Mt |
|---:|---:|
| 2021 | 1.212 |
| 2022 | 1.223 |
| 2023 | 1.309 |
| 2024 | 1.326 |
| 2025 | 1.404 |
| **Soma** | **6.474** |

TEU (flag MC): 11,8 → 11,7 → 11,6 → 13,9 → 15,2 milhões; total **64,3 milhões**. Contêiner cresce em TEU mais que o peso total - mix.

### 5.3 Conteúdo do contêiner (líquido)

68,2 milhões de linhas; 9,02 milhões de `IDCarga` distintos; 1.425 NCM. Peso líquido: 107, 103, 102, 125 e 132 milhões de t (2021-2025). Zeros: ~2,3 milhões de linhas/ano (vazio). Soma do líquido (**~569 milhões de t** no quinquênio) **<** peso bruto conteinerizado (707 milhões de t) - a diferença é tara, como o dicionário manda.

### 5.4 Ocupação do berço (minutos / dia)

Dia = 1.440 min. Mediana = **0** todos os anos: a maioria dos berço-dias está ociosa.

| Ano | Berços | % dias zerados | % dias 1.440 | TO média |
|---|---:|---:|---:|---:|
| 2021 | 877 | 62,2 | 19,3 | 0,302 |
| 2022 | 884 | 61,4 | 19,6 | 0,307 |
| 2023 | 893 | 60,4 | 19,9 | 0,315 |
| 2024 | 896 | 60,3 | 19,6 | 0,317 |
| 2025 | 896 | 59,7 | 19,3 | 0,320 |

TO média sobe de 30,2% para 32,0%. A distribuição é **bimodal** (0 e 1.440), não gaussiana. Não use `lm` em minutos crus sem transformar ou modelar zero-inflacionado.

---

## 6. Bivariada e hierarquia (o que quebra i.i.d.)

### 6.1 Frequência vs peso, de novo

Interior: muitas escalas, pouco peso. Granel sólido: poucas partidas, 60% das toneladas. Qualquer PCA em perfil de porto deve **padronizar** participação percentual, não usar contagem crua.

### 6.2 Cabotagem: duas flags, dois totais

| Conceito | Flag | Peso (t, MC) |
|---|---|---:|
| Transporte (viagem conta 1 vez) | `FlagCabotagem == 1` | 1.056 milhões de t |
| Movimentação (origem + destino) | `FlagCabotagemMovimentacao == 1` | 1.456 milhões de t |
| Razão | mov / transp | **1,38** |

Não é 2,000 porque nem todo fluxo tem os dois extremos no SDP com a mesma flag. **Declare qual total é o seu.** Somar cabotagem sem flag superestima o transporte.

Linhas: flag transporte = 1 em 1.170.396; flag movimentação = 1 em 2.173.530 (razão de linhas ≈ 1,86).

### 6.3 Longo curso vs cabotagem vs interior no peso

Longo curso **4,59 bilhões de t** (exportação 3,69 bilhões de t só no tipo de operação “Longo Curso Exportação”). Cabotagem 1,46 bilhão de t. Interior 0,41 bilhão de t. Inferência sobre “logística Brasil” sem estratificar navegação mistura minério para a China com barcaça no Tapajós.

### 6.4 Hidrovias e rios (subconjunto interior)

Peso alocado a hidrovia no quinquênio: **942 milhões de t**. Top de linhas: Hidrovia do Amazonas, Baixo Amazonas, Baixo Tocantins, Madeira.  
Regiões: Amazônica (1,25 M linhas), Tocantins-Araguaia (0,65 M).  
Rios (linhas): Negro, Pará, Guamá, Madeira, Amazonas, Tapajós.

Há dois rótulos quase duplicados (“Hidrovia do Amazonas” e “Hidrovia do Baixo Amazonas”) - recode antes de agregar.

### 6.5 Operadores (2023-2025)

Concentração alta em terminais de contêiner: Portonave, Santos Brasil, BTP, Brasil Port (offshore/estaleiro), Super Terminais (Manaus), J. F. de Oliveira. CNPJ distinto: ~319-346/ano. Cardinalidade usável em fator; ainda assim, *target encoding* só **dentro** do fold de treino.

### 6.6 Dependência intra-escala

11,0 milhões de partidas MC em 396 mil escalas com carga ⇒ **~28 partidas por escala** em média (muito maior em porta-contêineres). Resíduos de um `lm` na linha de carga **não** são independentes. Validação: bloco por `IDAtracacao`, por `CDTUP` ou por mês - nunca K-fold aleatório na partida.

### 6.7 Paralisações

~6-11 mil escalas/ano com pelo menos um evento (2021-2025: 6.602 → 10.891). Motivos estáveis: chuva, espera de caminhão, mudança de porão, quebra de equipamento, maré. 2024+: “Aguardando carga” passa a dominar (mudança de reporting).

---

## 7. Tempo e sazonalidade

- Escalas crescem todo ano; peso MC também, com aceleração 2022-2023 e 2024-2025.
- TEU cai levemente até 2023 e **salta** em 2024-2025.
- Mês: vale em janeiro (recesso + água baixa em parte da Amazônia); platô mar-ago.
- Para modelo preditivo: treino 2021-2023, validação 2024, teste 2025 (ou walk-forward). Misturar anos em K-fold aleatório **vaza** safra e hidrologia.

---

## 8. Laboratório da Aula 03 (o que o PDF pede entregar)

Variável quantitativa escolhida: **T3 = `TOperacao`** (horas), escalas 2024 com
`Tipo de Operação == "Movimentação da Carga"` e T3 válido (\(n = 74.518\)).

Números obtidos em R (`summary` / `sd`):

| Estatística | Valor (h) |
|---|---:|
| Mínimo | 0,02 |
| 1º quartil | 2,43 |
| Mediana | 8,00 |
| Média | 21,85 |
| 3º quartil | 25,33 |
| Máximo | 700 |
| Desvio padrão | 35,43 |
| Média / mediana | ≈ 2,73 |

Figuras geradas em R (`par(pty = "s")`): PNGs na pasta [`graficos/ampla/`](graficos/ampla/); script [`modelo_graficos_analise_ampla.R`](modelo_graficos_analise_ampla.R).

Não faça histograma de `CDTUP` nem boxplot de IMO (Aula 02: código não é número).

### 8.1 Gráfico 1 - histograma quadrado + Normal (itens 1 e 3 do lab)

`par(pty = "s")`, `hist(..., prob = TRUE)` e `curve(dnorm(...), add = TRUE)`.
O PDF também pede `boxplot` da mesma quantitativa; o univariado fica no código abaixo
e o por grupo (mais informativo) é o gráfico 2.

```r
par(pty = "s")
summary(t3)
sd(t3, na.rm = TRUE)
t3_cap <- t3[t3 <= quantile(t3, 0.99, na.rm = TRUE)]
hist(t3_cap, breaks = 40, prob = TRUE,
     main = "T3 (ate P99)", xlab = "TOperacao (horas)", ylab = "Densidade")
curve(dnorm(x, mean = mean(t3_cap), sd = sd(t3_cap)),
      add = TRUE, lwd = 2)

# boxplot univariado da mesma variavel (pedido do lab)
par(pty = "s")
boxplot(t3_cap, main = "T3 - boxplot", ylab = "TOperacao (horas)")
```

![Histograma de T3 com densidade Normal](graficos/ampla/01_t3_hist_dnorm.png)

**Comentário.** A massa se concentra perto de 0-20 h e a cauda se estende. A curva Normal (mesma média e desvio) fica larga demais no centro e não acompanha o pico nem a cauda. A Normal **não** descreve T3.

### 8.2 Gráfico 2 - boxplot quadrado por região (item 2 do lab)

Relação entre duas variáveis: T3 (quantitativa) × `Região Geográfica` (qualitativa).
`outline = FALSE` para ler o corpo, não os extremos de cadastro.

```r
par(pty = "s")
boxplot(TOperacao ~ `Região Geográfica`, data = mc,
        outline = FALSE, las = 2,
        main = "T3 por Regiao Geografica (2024, carga)",
        xlab = "", ylab = "TOperacao (horas)")
```

![Boxplot de T3 por região](graficos/ampla/02_t3_boxplot_regiao.png)

**Comentário.** As medianas diferem por região (Norte mais curto por mix interior; Sudeste/Sul mais longos no perfil de granel e longo curso). A amostra **não** é i.i.d. entre portos (liga com a seção 6).

### 8.3 Galeria Santos (10 gráficos com insight)

Recorte: **`Complexo Portuário == "Santos"`**, 2024. Em números: **6.292** escalas,
**5.739** de movimentação de carga com T3 válido, **172,2 Mt** (flag MC) e
**~4,84 milhões de TEU**. T3 mediano em Santos ≈ **30,4 h** (demais Sudeste ≈ 23,3 h);
T1 mediano ≈ **28,4 h** (fila relevante).

Os gráficos 01-02 cumprem o PDF no Brasil. Os 10 abaixo contam a história
operacional de Santos (tipos variados + alinhados à EDA: assimetria, hierarquia,
navegação × tonelagem, sazonalidade).

| # | Arquivo | Tipo | Insight |
|:-:|---|---|---|
| 03 | `03_santos_escalas_mes.png` | barras + linha | sazonalidade das escalas no complexo |
| 04 | `04_santos_navegacao.png` | barras % horizontais | domínio do longo curso nas escalas de carga |
| 05 | `05_santos_t3_navegacao.png` | boxplot por grupo | T3 muda com o tipo de navegação |
| 06 | `06_santos_top_bercos.png` | barras horizontais | concentração de escalas em poucos berços |
| 07 | `07_santos_peso_natureza.png` | barras horizontais (Mt) | granel sólido lidera tonelagem; contêiner vem atrás |
| 08 | `08_santos_sentido_peso.png` | barras (Mt) | mais peso embarcado que desembarcado (exportador) |
| 09 | `09_santos_peso_vs_t3.png` | dispersão + `lm` | peso da escala × tempo de operação (prancha) |
| 10 | `10_santos_vs_sudeste_t3.png` | densidades sobrepostas | Santos opera mais lento que o restante do Sudeste |
| 11 | `11_santos_fila_mes.png` | série (mediana e P90) | fila (T1) ao longo do ano |
| 12 | `12_santos_mes_navegacao.png` | mosaico | mix mês × navegação |

![Santos - escalas por mês](graficos/ampla/03_santos_escalas_mes.png)

**03.** Escalas relativamente estáveis no ano (linha + média tracejada). O pulso de
Santos é comercial, não hidrológico como no Norte da EDA nacional.

![Santos - navegação](graficos/ampla/04_santos_navegacao.png)

**04.** Nas escalas de carga, **longo curso** domina; cabotagem é secundária.
Casa com a EDA: tonelagem de Santos é comércio exterior.

![Santos - T3 por navegação](graficos/ampla/05_santos_t3_navegacao.png)

**05.** T3 muda com a navegação. Misturar longo curso e cabotagem num único `lm`
sem estratificar é o erro que a EDA proíbe (não i.i.d.).

![Santos - top berços](graficos/ampla/06_santos_top_bercos.png)

**06.** Poucos berços concentram muitas escalas. Validação deve considerar berço/`CDTUP`,
não só "o porto" como bloco homogêneo.

![Santos - peso por natureza](graficos/ampla/07_santos_peso_natureza.png)

**07.** Em toneladas, **granel sólido** lidera; contêiner é forte em TEU/linhas, mas
não em Mt. Contar partidas ≠ contar peso (mesma leitura da EDA, agora em Santos).

![Santos - sentido do peso](graficos/ampla/08_santos_sentido_peso.png)

**08.** Peso **embarcado** (~127 Mt) >> **desembarcado** (~45 Mt): perfil
**exportador em toneladas** no recorte 2024.

![Santos - peso vs T3](graficos/ampla/09_santos_peso_vs_t3.png)

**09.** Em escala log, peso da escala e T3 andam juntos (reta `lm`), com nuvem larga.
Bom candidato a \(Y=\log1p(T3)\) com \(\log1p(\text{peso})\) como \(X\).

![Santos vs Sudeste - T3](graficos/ampla/10_santos_vs_sudeste_t3.png)

**10.** Densidade de T3 em Santos fica à direita do demais Sudeste: mediana ~30 h vs
~23 h. Santos não é o "Sudeste médio" - é um regime próprio de fila e operação.

![Santos - fila T1 no ano](graficos/ampla/11_santos_fila_mes.png)

**11.** Mediana e P90 de T1 (espera) no calendário. Mediana = navio típico; P90 =
regime de congestionamento (como na EDA nacional: média/P90 ≠ mediana).

![Santos - mês × navegação](graficos/ampla/12_santos_mes_navegacao.png)

**12.** O mosaico mês × navegação mostra mix não uniforme no calendário. Partição
temporal e dummies de mês importam antes de estimar \(f\).

### 8.4 Frase da entrega (forma da distribuição)

> T3 é **assimétrica à direita** (média 21,9 h bem maior que a mediana 8,0 h): a forma lembra uma **Exponencial** (ou lognormal), com muita probabilidade perto de zero e cauda longa; **não** lembra Normal.

### 8.5 Variáveis aleatórias no banco (ponte com a Aula 03)

| Família (Aula 03) | Exemplo no banco | Problema-modelo |
|---|---|---|
| Bernoulli | escala com paralisação (sim/não); contêiner cheio vs vazio | ensaio binário |
| Binomial | nº de partidas granel em \(n\) escalas de um porto-mês | contagem com \(n\) fixo |
| Poisson | nº de paralisações por escala-dia | contagem de eventos raros |
| Normal | *não* é o caso de T3 nem do peso na linha | só após transformação e checagem |
| Exponencial | T1, T3, TE (tempos de espera/operação) | tempo até um evento / duração com cauda |

### 8.6 Faltantes no R (item 4 do lab)

```r
colSums(is.na(dt))           # por coluna, no join atracacao+tempos
sum(is.na(dt$TOperacao))     # T3: 10.424 / 106.834 em 2024 (~9,8%)
```

Detalhe por campo no quinquênio: seção 3.

---

## 9. Implicações para estimar \(f\) (Aula 01)

| Escolha | Evidência nesta EDA | Consequência |
|---|---|---|
| Unidade = partida de carga | 28 partidas/escala; 82% das linhas são contêiner de ~11 t | \(Y\) = peso é quase um modelo de granel disfarçado; cluster-robust ou agregar |
| Unidade = escala de movimentação | 359 mil escalas de carga; T3 mediano 8,7 h, cauda pesada | Melhor \(n\) para regressão de tempos; filtrar tipo de operação (flag MC da atracação é inútil aqui) |
| \(Y\) = T3 | 7,8% NA; identidade com TA/TE | Nunca usar TA, TE, T4 como \(X\); `log1p`; P99 |
| \(Y\) = T1 (fila) | média 47 h vs mediana 2 h no recorte carga | Classificação T1 > 12 h ou regressão quantílica; ocupação **defasada**, não do mesmo dia |
| \(Y\) = natureza | 82% conteinerizada nas linhas | Acurácia burra alta; use F1 / balanceamento / agregue à escala (moda ponderada por peso) |
| \(X\) = porto ou NCM | 234 TUP, 855-1.403 códigos | `glmnet`, embeddings ou nomenclatura simplificada (159 níveis) |
| Cabotagem | razão mov/transp = 1,38 | vazamento de definição do alvo se misturar flags |
| Áreas/CNPJ | só 2023+ | não treine 2021-2022 com esse \(X\) |
| Ocupação | 60% zeros, 19% uns | não é gaussiana; agregue berço-mês ou use defasagem |
| i.i.d. | porto, mês, escala | blocked CV; *hold-out* temporal |

**Resposta quantitativa ⇒ regressão; qualitativa ⇒ classificação** (Aula 02). Neste banco as duas convivem: declare \(Y\) **depois** desta EDA, não antes.

---

## 10. Recorte recomendado para o primeiro modelo

Objetivo didático (regressão, Bloco I-II da disciplina):

1. Anos 2021-2025, tabela `Atracacao` ⋈ `TemposAtracacao`.
2. `Tipo de Operação == "Movimentação da Carga"` e T3 não faltante.
3. Agregar `Carga` (flag MC) por `IDAtracacao`: peso, TEU, natureza modal (por peso), navegação modal.
4. \(Y = \log1p(\texttt{TOperacao})\).
5. \(X\): complexo ou região, mês (ordered → dummies), navegação, natureza modal, \(\log1p(\text{peso})\), indicador de rio.
6. Treino ≤ 2023, teste 2025.
7. Baseline: `lm`. Regularização: `glmnet` se usar dummies de complexo.

Isso cabe em um script R, respeita tipos, flags e vazamento, e ainda deixa um resíduo com cauda - material para a aula de viés-variância.

---

## 11. Como reproduzir (R)

Toda a EDA desta entrega foi feita em **R** (`data.table::fread` + base). Na raiz do repositório:

```r
library(data.table)
ler <- function(f) fread(f, sep = ";", dec = ",", encoding = "UTF-8",
                         na.strings = c("", "n/a", "NA"))

atrac <- rbindlist(lapply(2021:2025, function(a)
  ler(file.path("DatasetMovimentacaoPortuaria", a, paste0(a, "Atracacao.txt")))))

# qualitativas
table(atrac$`Tipo de Operação`, useNA = "ifany")
prop.table(table(atrac$`Região Geográfica`))

# quantitativa - depois do join com tempos
summary(tempos$TOperacao)
quantile(tempos$TOperacao, c(0.5, 0.95, 0.99), na.rm = TRUE)

# nunca:
# mean(as.numeric(atrac$CDTUP))
```

---

## 12. Síntese em um parágrafo (para o relatório)

O dump ANTAQ 2021-2025 contém 481 mil escalas (1:1 com tempos), 11,7 milhões de partidas de carga (11,0 milhões na apuração oficial) e 68 milhões de linhas de conteúdo de contêiner. A contagem de escalas é dominada pela navegação interior no Norte; a tonelagem (6,47 bilhões de t com flag MC) é dominada por granel sólido e longo curso. Tempos de operação têm mediana de 7-9 h e média três vezes maior (cauda de fila e de granel). A flag de movimentação da atracação não varia neste extract; origem/destino vazios coincidem com flag de carga = 0; áreas só existem a partir de 2023; paralisações mudam de padrão em 2024. Qualquer estimativa de \(f\) precisa fixar a unidade (escala vs partida), as flags de cabotagem, a partição temporal e o fato de que linhas da mesma escala não são i.i.d.

---

*Cálculos sobre o repositório local (EDA em R, 2026-08-24). Se o dump mudar, refazer as tabelas de \(n\) e de peso - os mecanismos (assimetria, flags, hierarquia) devem permanecer.*
