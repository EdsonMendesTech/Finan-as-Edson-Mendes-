# Finanças Edson Mendes — controle de acesso

## Estado atual

A interface em `index.html` é apenas uma **demonstração visual**. Não tem autenticação real, armazenamento persistente nem autorização de clientes. **Não usar para dados reais.** O aplicativo Base44 original não foi copiado nem alterado.

## Estrutura preparada

- `supabase/schema.sql`: tabelas de usuários e lançamentos, políticas RLS de isolamento, perfil inicial pendente, papéis de administrador/cliente e liberação/bloqueio pelo administrador.
- `index.html`: protótipo estático atual; **não está ligado ao Supabase**.

## Próximas etapas obrigatórias

1. Criar projeto privado no Supabase sob controle do proprietário e executar `supabase/schema.sql` no SQL Editor.
2. Desabilitar cadastro público de usuários no Supabase Auth. Criar/convocar os clientes apenas pelo painel administrativo do provedor ou por endpoint seguro no servidor.
3. Criar primeiro usuário no Supabase Auth; usar seu UUID na instrução de promoção a admin comentada no final do SQL.
4. Construir frontend autenticado e integrar as operações financeiras ao Supabase, sempre com sessão de usuário; construir painel administrativo para ativar/bloquear contas.
5. Testar com duas contas distintas, confirmar isolamento e bloqueio imediato antes de aceitar dados reais.
6. Obter exportação autorizada do Base44 para importar dados reais. **Não copiar senhas ou tokens.**
7. Hospedar o aplicativo por HTTPS, configurar domínio e rotas de autenticação.

## Segurança

Este repositório é **público**. Não envie dados de clientes, CPF/CNPJ, senhas, chaves secretas, backups de produção ou `service_role`. Uma chave pública anon do Supabase só pode ser usada depois que as políticas RLS estiverem testadas. O GitHub Pages sozinho não fornece backend ou login seguro.
