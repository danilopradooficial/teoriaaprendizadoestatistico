# Consolidado - Teoria do Aprendizado Estatístico - Aula 05b (Poisson) - 2026-10-25
*guia versão 1 · tutora: Cursor / Composer · sessão individual (teoria)*
**Aluno:** Danilo Prado de Lima Silva

## 1. O que foi passado
- M1 - contagens e a Poisson; a reta prevê visitas negativas
- M2 - $\log\lambda$ como reta; $e^{\beta}$ como razão de taxas ($e^{-0{,}5}=0{,}607$)
- M3 - `glm(family = poisson)`; coef 1,5738 / -0,5217 / 0,0653; previsão 6,27 visitas
- M4 - o offset; sem ele dist = 0,832, com ele 0,621 (verdade 0,607)
- M5 - sobredispersão; $\hat\phi=0{,}91$ (visitas) e $3{,}37$ (visitas_od); quase-Poisson
- M6 - Poisson contra MQO na CV(5): base 3,99 / MQO 2,39 / Poisson 1,76

## 2. Como foi o aprendizado - opinião da tutora
Conferiu a primeira célula (836 / 775 / 550) sem atrito. Leu $e^{\beta}$ como multiplicador depois de um empurrão no M2 (quase falou "menos 0,5 visita"). Montou o `glm` e o `predict(type = "response")` sozinho. No offset entendeu por que a praia "parecia fraca" sem os dias. Corrigiu a ideia de que $\hat\phi$ muda os coeficientes - bateu os dois `coef` iguais. No placar da CV previu que o Poisson ganharia antes de rodar.

**Teste final:** acertou M1-M6; a revisar M4 - verbalizar o offset ainda pede um segundo ("visitas por dia" vs "visitas no período").

## 3. Observações para a frente
- **Revisar antes da Parte D:** offset e $\hat\phi$; o $e^{\beta}$ na unidade do problema
- **Para a próxima tutora:** ritmo bom; pede LaTeX; Colab + calculadora lado a lado
- **Perguntas guardadas:** contagem no banco ANTAQ da Entrega 1 - Parte D
- **Produzido nesta sessão:** previsões do anúncio a 1 km / 12 fotos; placar 3,99 / 2,39 / 1,76
- **Parte D:** combinada para a sessão de grupo
