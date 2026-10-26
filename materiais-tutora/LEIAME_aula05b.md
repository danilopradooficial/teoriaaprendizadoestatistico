# LEIAME — Aula 05b, Regressão de Poisson (guia de estudo)
*Teoria do Aprendizado Estatístico · versão 1 — 2026-10-24 · para o professor*

## O que é

Um guia de estudo autônomo, em que uma LLM conduz o aluno, sobre um tema que **não é dado em
aula**: a regressão de Poisson, para respostas que são contagens. É a "terceira família" do
mapa com que a Aula 5 termina (linear e logística). O guia foi feito segundo
`COMO_CRIAR_GUIA_DE_ESTUDO.md` (versão 6, de 01/10/2026, o modelo de PI III), adaptado a esta
disciplina.

O nome `aula05b` segue a regra de meias-aulas do modelo: o guia pressupõe as Aulas 3 (a
distribuição de Poisson), 4 (MQO), 5 (logística e `glm`) e 7 (validação cruzada). As funções
de R que ele dá como vistas aparecem todas até a Aula 8 (a última é o `log`), e as dobras são
as da Aula 7 e dos laboratórios seguintes. Para esta turma, pode ser distribuído a qualquer
momento.

## Os arquivos, na ordem

| ordem | arquivo | para quem | quando | tempo |
|---|---|---|---|---|
| 1 | `GUIA_ESTUDO_aula05b.md` | cada aluno, sozinho | quando quiser | ~100 min |
| 2 | `GUIA_ESTUDO_aula05b_parteD.md` | o grupo reunido | depois do teste final da teoria | ~60 min |

Distribuir os dois arquivos juntos. Os alunos entregam no repositório do grupo:

- o consolidado individual, em `consolidados/<nome>/aula05b_consolidado.md`;
- o consolidado de grupo, em `consolidados/aula05b_parteD_consolidado.md`;
- o código da Parte D, em `estrutura/codigo/aula05b_poisson.R` (ou o `.ipynb`).

## O conteúdo

| módulo | tema | o que o aluno faz |
|---|---|---|
| 1 | contagens: por que a reta não serve | a reta prevê $-0{,}73$ visitas a 4,5 km; $P(Y=0)=e^{-\lambda}$ |
| 2 | $\log\lambda$ como reta | $e^{\beta}$ como razão de taxas; a razão constante $e^{-0{,}5}=0{,}607$ |
| 3 | ajustar e ler no R | `glm(family = poisson)`; previsão à mão; `type = "response"` |
| 4 | o *offset* | sem ele, a praia parece tirar 17% das visitas por km; com ele, 38% (verdade: 39%) |
| 5 | sobredispersão | $\hat\phi=3{,}37$; quase-Poisson; erros padrão $\times1{,}84$ |
| 6 | Poisson contra MQO | RMSE de validação cruzada: média $3{,}99$, MQO $2{,}39$, Poisson $1{,}76$ |
| 7–9 | Parte D | achar uma contagem no banco do grupo, ajustar e conferir, validar e decidir |

O exemplo é o da imobiliária do curso, agora com visitas aos anúncios. São três bases
simuladas (verdade conhecida), criadas pela primeira célula do guia com sementes fixas:
`anuncios` (200 anúncios em 30 dias), `anuncios$visitas_od` (as mesmas, com sobredispersão)
e `an2` (200 anúncios com 8 a 57 dias no ar). A linha de conferência devolve as somas 836,
775 e 550.

## Adaptações do modelo de PI III

O modelo foi escrito para o projeto do motor de busca. O que não se aplica aqui foi trocado:

- **Sem motor, sem `config.R` e sem `anexar_estado()`/`estado()`.** A primeira célula recria
  todas as bases a partir das sementes, e as somas conferem se o R do aluno reproduziu os
  números. Não há estado do R a carregar entre sessões.
- **A "ficha do projeto" virou a ficha da pergunta da Entrega 1.** A Parte D começa lendo
  essa ficha e dizendo de volta, em três linhas, o grupo, a pergunta e o banco.
- **Ambiente:** o R que o aluno usa nos laboratórios (RStudio ou Colab em R). As armadilhas
  do Colab estão na capa de cada arquivo.
- **"O que o aluno já sabe"** foi copiado dos slides e listas: Aula 3 (a Poisson e
  `dpois`), Aula 5 (o `glm`, o $e^{\beta}$ e o erro do `type = "response"`), Aulas 6 e 7, e
  as dobras da Aula 7 e dos laboratórios seguintes. A lista de funções de R já vistas saiu de
  um script que leu todos os `.Rnw` das Aulas 1 a 11. As funções novas estão marcadas no texto:
  `rpois`, `family = poisson` e `quasipoisson`, `offset`, `residuals(type = "pearson")`,
  `df.residual`, e, na Parte D, `as.data.frame` e `read.csv2`.
- **Da grade:** o Apêndice A do modelo vale como está, porque é a mesma turma (4º ciclo).

## Conferências feitas

- Todo o código do guia foi rodado numa sessão nova do R (4.3.3), e cada número do texto
  saiu da saída.
- Toda linha de código está comentada, e toda fórmula está em LaTeX.
- A teoria tem cerca de 5 mil palavras e a Parte D cerca de 2 mil, abaixo do limite de 6 mil
  por arquivo.

## Ainda não feito

- **O teste do modelo (seção 9.1):** percorrer a sessão inteira numa LLM nova, fazendo o
  papel de um aluno mediano, e depois numa segunda LLM.

## Para o professor decidir

1. Se o guia é só estudo, ou se a Parte D conta como etapa do trabalho.
2. Onde ficam os consolidados individuais: o guia sugere `consolidados/<nome>/`.
