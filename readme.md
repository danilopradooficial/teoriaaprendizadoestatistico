# Teoria do Aprendizado Estatístico

**Ciência de Dados · Fatec Rubens Lara - Baixada Santista**

Estimar e avaliar modelos de aprendizado a partir de dados - da regressão
às redes neurais e ao aprendizado não supervisionado - com
**pseudocódigo** e implementação em **R**.

![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)
![Status](https://img.shields.io/badge/status-em%20andamento-yellow)
![Banco](https://img.shields.io/badge/banco-ANTAQ%20local-lightgrey)

---

## Sobre a disciplina

**Objetivo:**  
Utilizar conhecimentos estatísticos para análise e projeto de algoritmos de aprendizado de máquina para modelar, compreender e analisar conjuntos de dados complexos. Escrever esses algoritmos em pseudocódigo e executá-los por meio de linguagens de programação. Utilizar os conhecimentos adquiridos em problemas de Ciência de Dados para fundamentar a tomada de decisões baseadas em informações obtidas por meio de algoritmos de aprendizado de máquina.

**Ementa:**  
Teoria da aprendizagem estatística. Métodos de reamostragem. Expansão e regularização. Métodos de suavização. Método EM (Expectation-Maximization). Avaliação e seleção de modelos. Árvores de decisão. Redes neurais e aprendizado de máquina (redes Adaline, Madaline, Perceptron e Multilayer Perceptron - MLP). Máquina de vetores suporte. Agrupamentos. Componentes principais e independentes. Aplicação desses conhecimentos para solução dos problemas de Ciência de Dados, utilizando linguagem de programação.

**Professor:**  
Prof. Dr. João Paulo Ferreira de Mello  
([joao.mello12@fatec.sp.gov.br](mailto:joao.mello12@fatec.sp.gov.br))

**Alunos:**  
Adriane da Costa Santos  
([adriane.santos01@aluno.cps.sp.gov.br](mailto:adriane.santos01@aluno.cps.sp.gov.br))

Danilo Prado de Lima Silva  
([danilo.silva25@aluno.cps.sp.gov.br](mailto:danilo.silva25@aluno.cps.sp.gov.br))

Victória Cabral Quintério  
([victoria.quinterio@aluno.cps.sp.gov.br](mailto:victoria.quinterio@aluno.cps.sp.gov.br))

**Linguagem das entregas:**  
Sempre **R base**.

**Banco de trabalho:**  
O Dataset de Dados Estatístico Aquaviário (ANTAQ ), recorte 2021-2025 está na pasta `DatasetMovimentacaoPortuaria` (~4,6 GB), que fica apenas na máquina local e no Google Drive, pelo tamanho não entra no GitHub.

---

## Cinco blocos do curso


| Bloco | Conteúdo                                          |
| ----- | ------------------------------------------------- |
| I     | Fundamentos do aprendizado estatístico            |
| II    | Supervisionado: avaliação e regularização         |
| III   | Modelos flexíveis: suavização, árvores, ensembles |
| IV    | Redes neurais e SVM                               |
| V     | Não supervisionado: agrupamento, EM, PCA/ICA      |


As Aulas 01-05 abrem o **Bloco I** e o início do supervisionado:
estimar \(f\), tipar dados, explorar, regressão linear e regressão logística.

---

## Estrutura do repositório

```
.
├── README.md
├── Atividades/
│   ├── atividade_01/
│   │   └── dicionario_variaveis_amplo_completo.md
│   ├── atividade_02/
│   │   ├── analise_exploratoria_ampla_completa.md      # exploracao larga (funil)
│   │   ├── analise_exploratoria_segmentada_entrega.md  # ENTREGA enxuta (tempos)
│   │   ├── modelo_graficos_analise_ampla.R
│   │   ├── modelo_graficos_analise_segmentada.R
│   │   └── graficos/
│   │       ├── ampla/                                  # PNGs da exploracao larga
│   │       └── segmentada/                             # PNGs da entrega (tempos)
│   ├── atividade_03/
│   │   ├── regressao_linear_e_previsao_t3.md
│   │   ├── modelo_regressao_linear_t3.R
│   │   ├── modelo_previsao_fila_t3.R
│   │   └── graficos/
│   └── atividade_04/
│       ├── regressao_logistica.md
│       ├── modelo_regressao_logistica.R
│       └── graficos/
├── MateriaisAulas/
│   ├── Aula 01 ... Aula 05
└── DatasetMovimentacaoPortuaria/         # LOCAL E GOOGLE DRIVE - fora do Git
```

- Teoria: [MateriaisAulas/](MateriaisAulas)
- Entregas: [Atividades/](Atividades)
- Na Atividade 02, a entrega oficial e
  `analise_exploratoria_segmentada_entrega.md` (tempos). A exploracao ampla
  fica em `analise_exploratoria_ampla_completa.md` (funil).
- Na Atividade 03, `regressao_linear_e_previsao_t3.md` traz a regressão de T3
  (peso + TEU) e a previsão para navios em T1/T2.

---

## Atividades × aulas

Cada pasta responde a um laboratório / “para casa” do PDF. O que o professor
pede explicitamente está na coluna **Pedido do PDF**; o `.md` pode ter
conteúdo **extra** para o semestre.


| #   | Entrega | Aula | Pedido do PDF | Status |
| --- | --- | --- | --- | --- |
| -   | *(em sala)* | [Aula 01](MateriaisAulas/Aula%2001%20-%20Introdução%20ao%20Aprendizado%20Estatístico.PDF) | Exercícios + lab de polinômios | Sem pasta no repo |
| 01  | [dicionario_variaveis_amplo_completo.md](Atividades/atividade_01/dicionario_variaveis_amplo_completo.md) | [Aula 02](MateriaisAulas/Aula%2002%20-%20Dados%20e%20Variáveis.PDF) | Dicionário do banco; pacote **base** | Entregue |
| 02A | [ampla completa](Atividades/atividade_02/analise_exploratoria_ampla_completa.md) | [Aula 03](MateriaisAulas/Aula%2003%20-%20Análise%20Exploratória%20e%20Variáveis%20Aleatórias.PDF) | Exploracao larga (rascunho / funil) | Mantida |
| 02B | [segmentada entrega](Atividades/atividade_02/analise_exploratoria_segmentada_entrega.md) | [Aula 03](MateriaisAulas/Aula%2003%20-%20Análise%20Exploratória%20e%20Variáveis%20Aleatórias.PDF) | *2 graficos + frase da forma* - foco **tempos T1-T4** | Entregue |
| 03  | [regressao_linear_e_previsao_t3.md](Atividades/atividade_03/regressao_linear_e_previsao_t3.md) | [Aula 04](MateriaisAulas/Aula%2004%20-%20Regressão%20Linear.PDF) | T3 ~ peso+TEU; previsao na fila (T1/T2) | Entregue |
| 04  | [regressao_logistica.md](Atividades/atividade_04/regressao_logistica.md) | [Aula 05](MateriaisAulas/Aula%2005%20-%20Classificação%20e%20Regressão%20Logística.PDF) | Y binario (T3 > 30 h), sigmoide, log-odds, odds - funil T3 | Entregue |


### Sequência no material

```
Aula 01                 Estimar f; predicao × inferencia; vies-variancia
        |
        v
Ativ 01 (Aula 02)       Dicionario + tipos
        |
        v
Ativ 02A (Aula 03)      EDA ampla (rascunho) --> achado: tempos do navio
        |
        v
Ativ 02B (Aula 03)      EDA segmentada ENTREGA: so T1, T2, T3, T4 (+ TA/TE)
        |
        v
Ativ 03 (Aula 04)       Regressao T3 ~ peso+TEU; previsao para T1/T2
        |
        v
Ativ 04 (Aula 05)       Regressao logistica: P(T3 > 30 h | peso + TEU)
        |
        v
…                       Matriz de confusao, KNN, ...
```


| De | Para | Por que |
| --- | --- | --- |
| Ativ 02A | Ativ 02B | Funil: da exploracao larga para o recorte de tempos |
| Ativ 02B | Ativ 03 | Assimetria de T3 e foco em operacao guiam o `lm` |
| Ativ 03 | Ativ 04 | Y quantitativo (T3) ⇒ regressao; Y binario ⇒ logistica |
| Ativ 04 | confusao / KNN | Probabilidade vira classe com limiar |


---

## Cruzamento com o material (ago/2026)

### Atividade 01 × Aula 02

**Mínimo da aula (cumprido).** Dicionário do ANTAQ no formato do slide:
nome, descrição, tipo (qualitativa/quantitativa), domínio; unidade amostral
por tabela; regra “código não é número” (`CDTUP`, IMO, NCM, …). Tipagem no
R (`factor`, `ordered`, `integer`, `double`, `character`) acompanha o lab
(`str`, `summary`, `factor`).

**Extra no** `.md` **(não pedido no slide).** Parte II: joins, flags,
volume, armadilhas e fluxo de leitura - útil no semestre, além do mínimo.

**Observação.** O PDF cita pacote **base**. Aqui `data.table::fread` entra
só porque o dump tem ~4,6 GB; a tipagem e os resumos seguem a base.

### Atividade 02 × Aula 03 (funil)

**02A - ampla completa (mantida).** Exploracao larga do ANTAQ (inventario,
carga, geografia, Santos…). Serviu para achar o tema. Graficos em
`Atividades/atividade_02/graficos/ampla/`.

**02B - segmentada (entrega).** So **tempos** T1-T4 (e TA/TE) em Santos 2024,
movimentacao de carga. Cumpre o lab da Aula 03 (hist+normal, boxplot por
grupo, frase da forma, faltantes) em texto enxuto.
Arquivo:
[analise_exploratoria_segmentada_entrega.md](Atividades/atividade_02/analise_exploratoria_segmentada_entrega.md).

### Atividade 03 × Aula 04

Um unico arquivo: [regressao_linear_e_previsao_t3.md](Atividades/atividade_03/regressao_linear_e_previsao_t3.md).
Regressão de T3 com tonelagem e TEU; mesma reta aplicada a navios em T1/T2.

### Atividade 04 × Aula 05

Fecha o funil em T3: Y binario (T3 > 30 h), mesmos preditores da Atividade 03
(`log1p(peso)` + `log1p(teu)`), curva sigmoide de **P(y=1|x)**, painel reta
log-odds → curva e contas de **odds** no peso mediano.
Arquivo: [regressao_logistica.md](Atividades/atividade_04/regressao_logistica.md).

---

## Banco local (ANTAQ)

Os microdados **não** estão neste repositório GitHub. Na máquina de trabalho:

`DatasetMovimentacaoPortuaria/` - texto `;`, vírgula decimal, anos 2021-2025.

Origem: [Estatístico Aquaviário](https://web.antaq.gov.br/) (ANTAQ / SDP).
Dados abertos - citar a ANTAQ em qualquer produto da disciplina.

Documentação (tipos, joins, flags, fluxo em R):
[dicionário de variáveis](Atividades/atividade_01/dicionario_variaveis_amplo_completo.md).

### Como reproduzir os gráficos e números

Na raiz do repositório, com `DatasetMovimentacaoPortuaria/` disponível:

```r
Rscript Atividades/atividade_02/modelo_graficos_analise_ampla.R
Rscript Atividades/atividade_02/modelo_graficos_analise_segmentada.R
Rscript Atividades/atividade_03/modelo_regressao_linear_t3.R
Rscript Atividades/atividade_03/modelo_previsao_fila_t3.R
Rscript Atividades/atividade_04/modelo_regressao_logistica.R
```

```r
library(data.table)
atrac <- fread(
  file.path("DatasetMovimentacaoPortuaria", "2024", "2024Atracacao.txt"),
  sep = ";", dec = ",", encoding = "UTF-8",
  na.strings = c("", "n/a", "NA", "N/A")
)
```

