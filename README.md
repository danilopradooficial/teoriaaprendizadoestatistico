# Teoria do Aprendizado Estatístico - Team Shannon

**Ciência de Dados · Fatec Rubens Lara - Baixada Santista**

Estimar e avaliar modelos de aprendizado a partir de dados - da regressão
às redes neurais e ao aprendizado não supervisionado - com
**pseudocódigo** e implementação em **R**.

![R](https://img.shields.io/badge/R-base-276DC3?style=flat&logo=r&logoColor=white)
![Status](https://img.shields.io/badge/status-em%20andamento-yellow)
![Equipe](https://img.shields.io/badge/equipe-Team%20Shannon-0B3954)
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

**Equipe:** Team Shannon  

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
O Dataset de Dados Estatístico Aquaviário (ANTAQ), recorte 2021-2025, está em `estrutura/dataset` (~4,6 GB). Fica só na máquina local e no Google Drive; pelo tamanho não entra no GitHub.

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

Mesmo padrão do Projeto Integrador III (mesmo professor e equipe).

```
.
├── README.md
├── estrutura/
│   ├── dataset/                  # ANTAQ local - fora do Git
│   └── codigos/                  # todos os scripts .R
│       ├── 01-dicionario-variaveis.R
│       ├── ...
│       ├── 09-splines-modelos-aditivos.R
│       └── aula05b-poisson.R     # Parte D da tutora (Poisson)
├── consolidados-aulas/           # relatórios técnicos das atividades
│   ├── 01-dicionario-variaveis.md
│   ├── ...
│   ├── 09-splines-modelos-aditivos.md
│   └── graficos/
├── consolidados-tutora/          # diários Colab (teoria + Parte D)
│   ├── aula05b_consolidado.md
│   └── aula05b_parteD_consolidado.md
├── materiais-tutora/             # GUIA_ESTUDO_*.md
├── entregas/                     # tudo das entregas avaliadas
│   └── entrega-1/
├── materiais-aulas/              # PDFs das aulas
└── to-delete-trash/              # layout antigo
```

| Pasta | Conteúdo |
|---|---|
| `estrutura/dataset` | Microdados ANTAQ (local, fora do Git) |
| `estrutura/codigos` | Códigos R das atividades e da Parte D da tutora |
| `consolidados-aulas` | Relatórios técnicos das atividades (grupo) |
| `consolidados-tutora` | Diários Colab: teoria (Danilo) + Parte D (grupo) |
| `materiais-tutora` | Guias `GUIA_ESTUDO_*.md` |
| `entregas` | Entregas avaliadas (PDF, .Rnw, código, dados) e modelos do professor |
| `materiais-aulas` | Slides/PDFs |
| `to-delete-trash` | Layout antigo - pode apagar depois de conferir |

---

## Atividades × Aulas

| # | Entrega (atividade) | Script | Tutora (teoria) | Tutora (Parte D) | Aula |
|---|---|---|---|---|---|
| 01 | [01-dicionario-variaveis.md](consolidados-aulas/01-dicionario-variaveis.md) | `01-dicionario-variaveis.R` | - | - | Aula 02 |
| 02a | [02a-analise-exploratoria-ampla.md](consolidados-aulas/02a-analise-exploratoria-ampla.md) | `02a-analise-exploratoria-ampla.R` | - | - | Aula 03 |
| 02b | [02b-analise-exploratoria-segmentada.md](consolidados-aulas/02b-analise-exploratoria-segmentada.md) | `02b-analise-exploratoria-segmentada.R` | - | - | Aula 03 |
| 03a | [03a-regressao-linear-t3.md](consolidados-aulas/03a-regressao-linear-t3.md) | `03a-regressao-linear-t3.R` | - | - | Aula 04 |
| 03b | [03b-previsao-fila-t3.md](consolidados-aulas/03b-previsao-fila-t3.md) | `03b-previsao-fila-t3.R` | - | - | Aula 04 |
| 04 | [04-regressao-logistica.md](consolidados-aulas/04-regressao-logistica.md) | `04-regressao-logistica.R` | - | - | Aula 05 |
| 05b | - | `aula05b-poisson.R` | [aula05b_consolidado.md](consolidados-tutora/aula05b_consolidado.md) | [aula05b_parteD_consolidado.md](consolidados-tutora/aula05b_parteD_consolidado.md) | Aula 05b |
| 05 | [05-avaliacao-selecao-modelos.md](consolidados-aulas/05-avaliacao-selecao-modelos.md) | `05-avaliacao-selecao-modelos.R` | - | - | Aula 06 |
| 06 | [06-metodos-reamostragem.md](consolidados-aulas/06-metodos-reamostragem.md) | `06-metodos-reamostragem.R` | - | - | Aula 07 |
| 07 | [07-expansao-regularizacao.md](consolidados-aulas/07-expansao-regularizacao.md) | `07-expansao-regularizacao.R` | - | - | Aula 08 |
| 08 | [08-metodos-suavizacao.md](consolidados-aulas/08-metodos-suavizacao.md) | `08-metodos-suavizacao.R` | - | - | Aula 09 |
| 09 | [09-splines-modelos-aditivos.md](consolidados-aulas/09-splines-modelos-aditivos.md) | `09-splines-modelos-aditivos.R` | - | - | Aula 10 |

Funil: dicionário → Análise Exploratória → T3 → escolha → CV/bootstrap → expansão e regularização → suavização → splines / GAM.

Guias Colab: [`materiais-tutora/`](materiais-tutora/) · diários: [`consolidados-tutora/`](consolidados-tutora/) (teoria = Danilo Prado de Lima Silva; Parte D = Team Shannon).

### Entregas avaliadas

| Entrega | Documento | Script | Prazo |
|---|---|---|---|
| 1 - A pergunta | [entrega-1-pergunta.pdf](entregas/entrega-1/entrega-1-pergunta.pdf) ([.Rnw](entregas/entrega-1/entrega-1-pergunta.Rnw)) | [entrega-1-pergunta.R](entregas/entrega-1/entrega-1-pergunta.R) | 09/10 |

Pergunta escolhida: *quando um navio é programado para atracar em Santos, quantas horas ele vai operar no berço?* Regressão preditiva de T3, métrica RMSE em horas. Na CV(5), o `lm` faz 23,7 h contra 32,8 h da linha de base (média).

---

## Como rodar os códigos

Na raiz do repositório, com `estrutura/dataset` disponível:

```bash
Rscript estrutura/codigos/01-dicionario-variaveis.R
Rscript estrutura/codigos/02a-analise-exploratoria-ampla.R
Rscript estrutura/codigos/02b-analise-exploratoria-segmentada.R
Rscript estrutura/codigos/03a-regressao-linear-t3.R
Rscript estrutura/codigos/03b-previsao-fila-t3.R
Rscript estrutura/codigos/04-regressao-logistica.R
Rscript estrutura/codigos/05-avaliacao-selecao-modelos.R
Rscript estrutura/codigos/06-metodos-reamostragem.R
Rscript estrutura/codigos/07-expansao-regularizacao.R
Rscript estrutura/codigos/08-metodos-suavizacao.R
Rscript estrutura/codigos/09-splines-modelos-aditivos.R
Rscript estrutura/codigos/aula05b-poisson.R
```

Para compilar a Entrega 1 (precisa de knitr e de um LaTeX com abntex2; o TinyTeX instala o que faltar):

```bash
Rscript entregas/entrega-1/entrega-1-pergunta.R
cd entregas/entrega-1
Rscript -e "knitr::knit2pdf('entrega-1-pergunta.Rnw', bib_engine = 'bibtex')"
```

Os scripts leem `estrutura/dataset` e gravam PNGs em `consolidados-aulas/graficos/`.
O nome casa em tudo: `09-splines-modelos-aditivos.R`, `09-splines-modelos-aditivos.md` e `09-numeros.txt` (o mesmo vale para 01-09).
Diários da tutora: `aula05b_consolidado.md` (teoria) e `aula05b_parteD_consolidado.md` (grupo).
