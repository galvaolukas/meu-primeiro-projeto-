# Modelo e exemplos de AGENTS.md

<!-- Tradução pt-BR de https://github.com/qingshan-dong/writing-agents-md — Licença MIT, (c) 2026 QingShan -->

## Modelo mínimo para começar

```markdown
# <Nome do projeto> · Acordos de colaboração

<Um parágrafo curto: o que é o projeto, para quem, o que o agente faz principalmente aqui, quem decide.>

## Regras globais

- <Prioridade de escolha: quando duas coisas conflitam, qual vem primeiro.>
- <Quais operações exigem confirmação antes; linhas vermelhas invioláveis, com a alternativa.>
- <Quando está concluído: que verificações usar e quando rodar.>

## Ler conforme o contexto

- <Ao fazer certo tipo de tarefa>, leia `<caminho real do arquivo>`, para <finalidade específica>.
```

## Antes e depois

Um app de controle financeiro feito por uma pessoa só; suponha que o projeto já declara no package.json o gerenciador de pacotes e os comandos comuns.

Antes:

```markdown
# Descrição do projeto

Este é um aplicativo web. Faça as tarefas com cuidado e profissionalismo, garantindo a qualidade do código.

- Antes de começar, leia todos os documentos em docs/.
- Depois de cada alteração no código, rode todos os testes.
- Não use o tipo any, não escreva código duplicado, não adicione dependências à toa.
- Use pnpm; iniciar é pnpm dev, testar é pnpm test.
- Componentes em src/components, APIs em src/api, estilos em src/styles.
- Confirme antes de apagar arquivos.
- Lembre de atualizar a documentação.
```

Depois:

```markdown
# App de finanças · Acordos de colaboração

Um app web de controle financeiro para pessoas físicas, desenvolvido só por mim. O agente ajuda a criar funcionalidades, corrigir bugs e completar testes; as decisões de produto são minhas.

## Regras globais

- Se experiência de uso e código limpo conflitarem, priorize a experiência.
- Antes de apagar arquivos, mudar a estrutura do banco de dados ou adicionar dependências, explique o motivo e espere minha confirmação.

## Ler conforme o contexto

- Antes de escrever código, leia docs/code-style.md e siga as convenções de tipos, reutilização e onde colocar arquivos.
- Antes de criar ou alterar APIs, leia docs/api.md e confira nomes e códigos de erro; depois, atualize esse documento.
- Antes de mexer na interface, leia docs/design.md e siga as regras de componentes e espaçamento.
- Depois de alterar código, rode os testes relacionados à mudança; se alterou um módulo compartilhado, rode todos os testes.
```

As regras movidas precisam ir junto para os arquivos correspondentes, não basta deixar o caminho. Ao mover, transforme exigências vagas em práticas executáveis; por exemplo, trocar "não escreva código duplicado" por "antes de criar algo novo, procure se já existe; se o existente atender, reutilize".

Item a item (categorias em "Critérios" no SKILL.md):

| Antes | Coluna | Tratamento | Por quê |
| --- | --- | --- | --- |
| Com cuidado, profissionalismo, qualidade | Excluir: inócua | Apagar | Escrever não muda nada |
| Ler todos os docs/ antes | Mover | Trocar por três ponteiros com momento certo | Ler tudo sempre; a maioria das tarefas não precisa |
| Rodar todos os testes após cada mudança | Manter: quando está concluído | Rodar conforme o alcance da mudança | Do jeito antigo, corrigir uma vírgula roda tudo |
| Não usar any | Mover | Para as convenções de tipo em docs/code-style.md | Só usado ao escrever código |
| Não duplicar código | Mover | Virar prática concreta de procurar e reutilizar, em docs/code-style.md | Mantém a exigência, tira a vagueza |
| Não adicionar dependências à toa | Manter: regra global | Juntar em "explique o motivo e espere confirmação" | Diz o que fazer; operações caras numa regra só |
| pnpm e comandos | Excluir: fácil de descobrir | Apagar | Já está no package.json |
| Pastas | Mover | Para docs/code-style.md | Onde pôr arquivos novos é convenção, não dá para deduzir só listando pastas |
| Confirmar antes de apagar | Manter: regra global | Juntar com banco de dados e dependências | Violar custa caro |
| Lembrar de atualizar documentação | Manter: ponteiro | "Após alterar APIs, atualize docs/api.md" | Diz o que atualizar e quando |
| — | Manter: apresentação | Adicionar apresentação e prioridades | O agente sabe que projeto é e o que priorizar |

Se "testes precisam passar para mesclar" ou "proibido any" forem exigências rígidas, acrescente "passar para ferramenta": configure os testes ou o ESLint `no-explicit-any`, rode no CI e torne obrigatório antes de mesclar; deixe uma frase no AGENTS.md. Se a ferramenta não estiver configurada, marque "a configurar" — não basta escrever uma frase e considerar que já vale.
