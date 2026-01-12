# pdialer-auto-remove

🚮 **Limpeza automática de logs do módulo Dialer (Issabel)**

Este repositório contém um instalador (`install_cleanup.sh`) que instala um script de limpeza responsável por remover arquivos de log antigos/inúteis gerados pelo módulo *dialer* do Issabel (arquivos `dialerd.log-*`). O objetivo é evitar que logs acumulados ocupem espaço desnecessário e manter o sistema mais organizado.

---

## ✅ O que faz

- Procura por arquivos `dialerd.log-*` em `/opt/issabel/dialer` e os remove.
- Registra cada ação em `/var/log/cleanup_dialerd.log` (tamanhos e sucessos/erros).
- Calcula o total de bytes removidos e grava um resumo ao final.
- Instala um job no `crontab` para executar diariamente às 02:00 por padrão.

---

## 🔧 Instalação

1. Torne o instalador executável (se necessário):

   ```bash
   chmod +x install_cleanup.sh
   sudo ./install_cleanup.sh
   ```

2. O instalador criará:
   - Script em: `/usr/local/bin/cleanup_dialerd.sh`
   - Log de auditoria: `/var/log/cleanup_dialerd.log`
   - Job do cron: `0 2 * * * sudo /usr/local/bin/cleanup_dialerd.sh # cleanup_dialerd`

3. Se o script já estiver instalado, o instalador oferece opções para reinstalar, desinstalar ou sair.

---

## ▶️ Uso

- Executar manualmente:

  ```bash
  sudo /usr/local/bin/cleanup_dialerd.sh
  ```

- Visualizar logs em tempo real:

  ```bash
  tail -f /var/log/cleanup_dialerd.log
  ```

- Conferir o crontab do usuário root:

  ```bash
  sudo crontab -l
  ```

- Desinstalar (pela interface do instalador): execute `sudo ./install_cleanup.sh` e escolha a opção 2 para remover cron e script.

Ou manualmente:

```bash
# remover job do cron com o identificador
sudo crontab -l | grep -v "cleanup_dialerd" | sudo crontab -
# remover script
sudo rm -f /usr/local/bin/cleanup_dialerd.sh
```

---

## ⚙️ Como o script funciona (resumo técnico)

- Verifica se é executado como `root` (exit se não for).
- Garante que o diretório de logs (`/opt/issabel/dialer`) exista; se não, escreve erro no log e sai.
- Para cada arquivo `dialerd.log-*`:
  - Calcula o tamanho,
  - Remove o arquivo,
  - Registra o resultado no `/var/log/cleanup_dialerd.log`.
- Ao final, registra o total de bytes deletados (e uma versão em formato humano quando possível).

---

## 🛠️ Configuração e personalização

- Para alterar o agendamento, edite a variável `CRON_SCHEDULE` dentro de `install_cleanup.sh` antes de executar o instalador.
- Se seus logs estiverem em outro diretório, edite `LOG_DIR` no script gerado (`/usr/local/bin/cleanup_dialerd.sh`).
- O instalador e o script definem permissões amplas no log (`chmod 666`). Para ambientes mais restritos, considere `chmod 640` e definir proprietário/grupo adequados (`root:adm`).

---

## 🐞 Problemas comuns & solução

- Cron não executa: verifique `crontab -l` e permita que `sudo` seja executado sem bloqueios. Confira também os paths absolutos e permissões do script.
- O script não encontra `/opt/issabel/dialer`: confirme o caminho e ajuste `LOG_DIR` se necessário.
- Logs de auditoria não presentes: verifique permissões e se o arquivo `/var/log/cleanup_dialerd.log` existe e é gravável.

---

## 🔐 Observações de segurança

- O script e o instalador precisam ser executados como `root`.
- Considere ajustar permissões dos arquivos de log se houver preocupações com exposição de informações.

---

## 📄 Licença

Consulte o arquivo `LICENSE` deste repositório para detalhes sobre a licença.

---

