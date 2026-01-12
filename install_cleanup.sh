#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Definições
SCRIPT_NAME="cleanup_dialerd.sh"
SCRIPT_PATH="/usr/local/bin/$SCRIPT_NAME"
CRON_SCHEDULE="0 2 * * *"
CRON_IDENTIFIER="cleanup_dialerd"
LOG_FILE="/var/log/cleanup_dialerd.log"

echo -e "${YELLOW}=== Installer - Limpeza Automática de Logs Dialerd ===${NC}\n"

# Verificar se já está instalado
if [ -f "$SCRIPT_PATH" ]; then
    echo -e "${YELLOW}⚠ O script já está instalado em $SCRIPT_PATH${NC}"
    
    # Verificar se está no crontab
    if crontab -l 2>/dev/null | grep -q "$CRON_IDENTIFIER"; then
        echo -e "${GREEN}✓ Tarefa cron também está configurada${NC}\n"
        
        echo "Opções:"
        echo "1 - Reinstalar (sobrescrever script e atualizar cron)"
        echo "2 - Desinstalar completamente"
        echo "3 - Sair"
        read -p "Escolha uma opção (1-3): " option
        
        case $option in
            1)
                echo -e "\n${YELLOW}Reinstalando...${NC}"
                ;;
            2)
                echo -e "\n${YELLOW}Desinstalando...${NC}"
                
                # Remover cron
                crontab -l 2>/dev/null | grep -v "$CRON_IDENTIFIER" | crontab - 2>/dev/null
                echo -e "${GREEN}✓ Tarefa cron removida${NC}"
                
                # Remover script
                rm -f "$SCRIPT_PATH"
                echo -e "${GREEN}✓ Script removido de $SCRIPT_PATH${NC}"
                
                echo -e "${GREEN}✓ Desinstalação concluída${NC}\n"
                exit 0
                ;;
            3)
                echo -e "${YELLOW}Operação cancelada${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}\n"
                exit 1
                ;;
        esac
    else
        echo -e "${YELLOW}⚠ Script existe, mas cron não está configurado${NC}"
        echo -e "${YELLOW}Atualizando apenas a tarefa cron...${NC}\n"
    fi
else
    echo -e "${GREEN}Script não encontrado, iniciando instalação...${NC}\n"
fi

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ Este installer precisa ser executado como root${NC}\n"
    exit 1
fi

# Criar o script
echo -e "${YELLOW}Criando script em $SCRIPT_PATH...${NC}"

cat > "$SCRIPT_PATH" << "EOF"
#!/bin/bash

LOG_DIR="/opt/issabel/dialer"
LOG_CLEANUP="/var/log/cleanup_dialerd.log"

touch "$LOG_CLEANUP"
chmod 666 "$LOG_CLEANUP"

log_cleanup() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_CLEANUP"
}

log_cleanup "=== Iniciando limpeza de logs ==="

TOTAL_DELETED=0

cd "$LOG_DIR" 2>/dev/null || {
    log_cleanup "✗ ERRO: Não conseguiu acessar $LOG_DIR"
    exit 1
}

for FILE_PATH in dialerd.log-*; do
    if [ -f "$FILE_PATH" ]; then
        SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null)
        SIZE_HUMAN=$(du -h "$FILE_PATH" | cut -f1)
        
        rm -f "$FILE_PATH"
        
        if [ ! -f "$FILE_PATH" ]; then
            log_cleanup "✓ DELETADO: $FILE_PATH | Tamanho: $SIZE_HUMAN"
            TOTAL_DELETED=$((TOTAL_DELETED + SIZE))
        else
            log_cleanup "✗ ERRO ao deletar: $FILE_PATH"
        fi
    fi
done

if [ "$TOTAL_DELETED" -gt 0 ]; then
    TOTAL_HUMAN=$(numfmt --to=iec-i --suffix=B $TOTAL_DELETED 2>/dev/null || echo "$((TOTAL_DELETED / 1073741824))GB")
else
    TOTAL_HUMAN="0B"
fi

log_cleanup "=== Resumo: Total deletado = $TOTAL_HUMAN ($TOTAL_DELETED bytes) ==="
log_cleanup ""

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Limpeza concluída. Total deletado: $TOTAL_HUMAN"
EOF

chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}✓ Script criado com sucesso${NC}"

# Configurar crontab
echo -e "${YELLOW}Configurando tarefa cron...${NC}"

crontab -l 2>/dev/null | grep -v "$CRON_IDENTIFIER" | crontab - 2>/dev/null

CRON_JOB="$CRON_SCHEDULE sudo $SCRIPT_PATH # $CRON_IDENTIFIER"
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

if crontab -l 2>/dev/null | grep -q "$CRON_IDENTIFIER"; then
    echo -e "${GREEN}✓ Tarefa cron configurada${NC}"
else
    echo -e "${RED}✗ Erro ao configurar crontab${NC}\n"
    exit 1
fi

touch "$LOG_FILE"
chmod 666 "$LOG_FILE"

echo -e "\n${GREEN}=== Instalação Concluída ===${NC}"
echo -e "Script instalado em: ${YELLOW}$SCRIPT_PATH${NC}"
echo -e "Log será salvo em: ${YELLOW}$LOG_FILE${NC}"
echo -e "Agendamento: ${YELLOW}Diariamente às 02:00 (2 AM)${NC}\n"

echo "Informações úteis:"
echo -e "  • Ver logs: ${YELLOW}tail -f $LOG_FILE${NC}"
echo -e "  • Executar manualmente: ${YELLOW}sudo $SCRIPT_PATH${NC}"
echo -e "  • Ver crontab: ${YELLOW}crontab -l${NC}"
echo -e "  • Desinstalar: ${YELLOW}sudo $0 (e escolher opção 2)${NC}\n"

echo -e "${GREEN}✓ Tudo pronto!${NC}\n"

sudo bash /usr/local/bin/cleanup_dialerd.sh