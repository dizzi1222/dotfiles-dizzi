#!/bin/bash
# SETUP RAPIDO OLLAMA CLOUD

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🤖 Descargando modelos Cloud para Ollama...${NC}"
echo ""
ollama pull qwen3-vl:235b-instruct-cloud
ollama pull qwen3-coder:480b-cloud
ollama pull gpt-oss:120b-cloud
ollama pull gemma3:27b-cloud
ollama pull deepseek-v3.1:671b-cloud
ollama pull deepseek-v3.2:cloud
ollama pull qwen3-next:80b-cloud
ollama pull gemini-3-flash-preview:cloud
ollama pull mistral-large-3:675b-cloud

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 TODO INSTALADO, recuerda logearte${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "ollama signin"
ollama signin
