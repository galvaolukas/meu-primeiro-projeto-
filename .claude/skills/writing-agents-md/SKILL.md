---
name: writing-agents-md
description: Criar, revisar ou modificar arquivos de regras permanentes para agentes (AGENTS.md, CLAUDE.md, GEMINI.md, regras do Cursor).
---

<!--
Tradução para pt-BR de https://github.com/qingshan-dong/writing-agents-md
Licença MIT - Copyright (c) 2026 QingShan. Veja LICENSE nesta pasta.
-->

# Escrevendo AGENTS.md

Verifique uma a uma as regras permanentes do AGENTS.md, CLAUDE.md etc.: o que vale a pena aplicar em toda tarefa fica; as demais regras passam a ser lidas sob demanda.

| Modo                     | Etapas      | Entrega                              |
| ------------------------ | ----------- | ------------------------------------ |
| Criar (ainda não existe) | 1, 3, 5, 6  | Rascunho candidato                   |
| Revisar (só opinião)     | 1–4, 6      | Problemas e sugestões, sem alterar   |
| Modificar                | 1–6         | Alterações                           |

As etapas 1–4 apenas analisam, sem alterar arquivos. As etapas 1, 3 e 4 seguem os "Critérios" abaixo.

## 1. Extrair o essencial

Leia o arquivo existente, os arquivos para os quais ele aponta, as regras citadas pelo usuário e a descrição do projeto. Ao criar do zero, leia as instruções do usuário e a documentação existente. Classifique cada frase em quatro colunas: manter, passar para ferramenta, mover para outro arquivo, candidata a exclusão.

Só conta como base o que o usuário disse explicitamente. Regras existentes já commitadas contam; sugestões de agentes anteriores em conversas ou registros não contam. O que não puder ser confirmado, marque como "a verificar".

Compare com cada categoria de "Manter" para achar lacunas, por exemplo: tarefas comuns sem ponto de partida, ou falta dizer quando algo está concluído.

Pronto quando: os materiais lidos estão listados; toda frase tem coluna; cada item mantido tem justificativa; as lacunas estão listadas.

## 2. Encontrar conflitos

Verifique as colunas e os materiais lidos em busca de contradições, repetições e formulações divergentes. Material arquivado serve só para rastrear a origem, não como base vigente.

Para cada caso, dê duas redações e recomende uma. Junto com os itens "a verificar" e as lacunas da etapa 1, leve ao usuário para decidir. Se conflitar com um acordo de longo prazo, pergunte se é exceção desta vez ou mudança permanente.

Pronto quando: cada item tem recomendação ou está marcado para decisão do usuário.

## 3. Classificar e mover

Agrupe os itens a mover por tipo de tarefa no arquivo adequado, deixando um ponteiro no AGENTS.md. Para os itens passados a ferramentas, indique a ferramenta e deixe uma frase de explicação no AGENTS.md. Na revisão, apenas sugira.

Pronto quando: cada item tem destino e cada ponteiro tem contexto.

## 4. Marcar exclusões

Classifique frase a frase conforme as categorias de "Candidatas a exclusão". Na dúvida, compare com a tabela item a item de `references/EXAMPLES.md`.

Liste à parte as mudanças de comportamento: força da restrição, alcance de leitura, obrigação de confirmar. Confira com a etapa 3: o sentido não muda; as tarefas que usavam a regra ainda a encontram e ainda são lembradas de lê-la.

Ao renomear ou mover um título, procure em todo o repositório os links de âncora que apontam para ele e ajuste-os juntos.

Pronto quando: cada exclusão/alteração tem justificativa e as mudanças de comportamento estão listadas.

## 5. Redigir e simular

Com base em `references/EXAMPLES.md`, produza o rascunho mais enxuto e os arquivos para onde as regras foram movidas. Redija conforme "Como escrever". Se a estrutura existente for razoável, mantenha-a; o modelo é só referência.

Simule o uso e indique como foi feito. Se houver subagente, entregue a ele apenas o novo rascunho e três cenários: típico, limite e que não deveria acionar. Peça que liste o que leria e o que faria, apontando ambiguidades e acionamentos indevidos. Sem subagente, simule você mesmo os três cenários, registrando antes de avaliar.

Corrija conforme a simulação. Liste à parte o que não puder corrigir. Se a correção mudar o comportamento, simule outra rodada da mesma forma.

Pronto quando: o rascunho está pronto, a simulação foi feita e o método indicado, os problemas foram corrigidos ou listados, e a versão final foi simulada.

## 6. Entregar

- Revisão: ordene os problemas primeiro pelo impacto no comportamento, depois pela frequência. Cada item com sugestão.
- Modificação: ajustes só de redação, aplique direto conforme autorizado. Reorganizar títulos, excluir ou mover regras: primeiro entregue o rascunho candidato e aplique após confirmação.
- Criação: entregue o rascunho candidato e grave após confirmação. Lacunas da etapa 1 que não puderem ser preenchidas, liste para o usuário completar.

Releia o arquivo antes de aplicar. Indique separadamente o que é candidato, aplicado e testado na prática. Liste à parte os itens "a testar" para o usuário observar no uso real. Lembre o usuário: as mudanças podem só valer numa nova sessão.

Pronto quando: a entrega bate com o relatório e cada item tem seu status indicado.

## Critérios

### Manter

- **Apresentação do projeto**: o que é, para quem, o que o agente faz aqui, quem decide.
- **Quando está concluído**: indique as verificações, quando rodam e o alcance. Escolha as verificações conforme o impacto da mudança, sem exigir genericamente rodar tudo sempre.
- **Regras globais**: não descobríveis no ambiente, que o modelo não seguiria por padrão, e que atendam a pelo menos um: usadas em todo tipo de tarefa; violação cara ou difícil de perceber; momento de aplicação imprevisível. Lembretes de correção comuns só viram permanentes se o erro se repetir. Linhas vermelhas de alto risco não precisam esperar o erro acontecer.
- **Ponteiros**: onde estão as demais regras. Indique contexto, caminho e finalidade, como "antes de escrever código de API, leia `docs/api.md` e confira nomes e códigos de erro".

### Passar para ferramenta

Exigências rígidas como testes passando, formatação uniforme ou arquivos que não podem ser apagados vão para CI, formatador, configurações de permissão ou hook.

Confira se a ferramenta está configurada, quando roda e se bloqueia em caso de falha. O que não estiver pronto, marque como "a configurar"; não conte como garantia existente. No AGENTS.md, deixe uma frase dizendo quando rodar localmente.

### Mover para outro arquivo

Convenções usadas só em certos tipos de tarefa (guia de design, convenções de backend, padrões de API) vão para o arquivo correspondente, com ponteiro no AGENTS.md.

- Um ponteiro não garante leitura. Regras importantes e caras de errar ficam no arquivo principal ou vão para ferramenta.
- Uma convenção, uma fonte. O ponteiro pode trazer um ponto-chave para corrigir um comportamento padrão da ferramenta ou um erro comum.
- Convenções específicas de uma pasta podem ir para o AGENTS.md daquela pasta. Se não tiver certeza de que a ferramenta principal carrega automaticamente, deixe um ponteiro no arquivo raiz como garantia.
- Com poucas regras, não divida.

### Candidatas a exclusão

- **Fácil de descobrir**: dependências, estrutura de pastas atual, comandos já definidos no package.json. O que for trabalhoso ou fácil de errar ao procurar, deixe uma frase, como qual dos vários comandos de teste usar no dia a dia. Onde colocar arquivos novos, convenções não escritas e o motivo por trás de uma prática: mantenha ou mova por tarefa; não dá para deduzir só olhando o estado atual.
- **Repetida**: mantenha no lugar mais próximo de onde é usada.
- **Inócua**: se apagar não muda o comportamento, apague a frase inteira. Na dúvida, marque "a testar".
- **Vaga**: se não dá para seguir nem verificar, reescreva como comportamento-alvo ou apague.
- **Desatualizada**: julgue pelo ambiente de hoje. Ao revisar versões antigas, distinga o que já estava errado do que ficou desatualizado depois.

Arquivos de regras gerados automaticamente costumam ser grandes e genéricos; depois de gerar, passe por todos os itens acima.

### Como escrever

Escreva o que fazer. O que for preciso proibir, acompanhe da alternativa. Fluxos sabidamente seguros: escreva a autorização direto, em vez de pedir confirmação a cada passo. Afirmações de fato precisam de fonte.

## Manutenção

Depois de trocar de modelo ou ferramenta, revise de novo e retire as regras que perderam efeito.
