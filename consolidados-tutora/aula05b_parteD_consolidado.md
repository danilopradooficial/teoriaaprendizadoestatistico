# Consolidado - Teoria do Aprendizado Estatístico - Aula 05b - Parte D - 2026-10-26
*guia versão 1 · tutora: Cursor / Composer · sessão de grupo*
**Grupo:** Team Shannon · **presentes:** Adriane, Danilo, Victória · **digitou:** M7: Danilo · M8: Adriane · M9: Victória

## 1. O que foi feito
- M7 - contagem (caso 2): escalas Santos 2024, movimentação de carga, por mês × navegação; 5.843 eventos → 48 linhas (12 × 4); 8 zeros mantidos; sem exposição diferente entre células
- M8 - modelo: `n ~ mes + navegacao`; $\hat\phi=0{,}82$ (Poisson serve); Longo Curso multiplica por ≈ 35,8 a taxa do Apoio Portuário (referência), com os outros fixos
- M9 - placar CV(5): base 167,7 · MQO 15,4 · Poisson 18,3; decisão: **MQO** no RMSE deste agregado; Poisson fica como opção coerente (nunca prevê negativo)

## 2. Como o grupo trabalhou - opinião da tutora
Decisões saíram do grupo: T3 da Entrega 1 não é contagem, então agregaram escalas (caso 2) em vez de forçar Poisson na ficha. Discutiram juntar navegações raras antes da CV (evitar nível novo na validação). Leram $e^{\beta}$ na unidade (vezes, não "escalas a mais") depois de um empurrão. No placar não maquiaram: MQO ganhou e ficaram com ele, sem insistir no Poisson só porque era o tema da aula.

**Verificação final:** acertou M7-M9; a revisar M8 - dizer o $e^{\beta}$ do mês ainda mistura "% a mais" com "pontos percentuais".

## 3. Observações para a frente
- **Para o trabalho:** a contagem é pergunta auxiliar (volume de escalas por mês/navegação). A ficha da Entrega 1 (T3 em horas, RMSE) **não muda** sem conversar com o professor
- **Perguntas guardadas:** vale offset com dias do mês? - se o professor pedir refino
- **Produzido:** `estrutura/codigos/aula05b-poisson.R` e placar 167,7 / 15,4 / 18,3
