#!/bin/bash
################################################################################
# ULTIMATE CRYPTO RECOVERY SUITE FOR KALI LINUX
# Version: 2.0
# Tools Integrated:
#   - BTCRecover (3rdIteration)     : Seed/Password recovery for 40+ wallets
#   - PyWallet (GSC/jackjack)       : wallet.dat dump, corrupt recovery, disk scan
#   - bitcoin2john + Hashcat        : GPU password cracking for wallet.dat
#   - John the Ripper (Jumbo)       : CPU password cracking
#   - py3ethrecover                 : Ethereum keystore password recovery
#   - Seed Phrase Scanner           : Filesystem scan for leaked BIP39 seeds
#   - MetaMask Vault Decryptor      : Offline vault recovery
#   - Ian Coleman BIP39             : Offline key derivation
#   - Seed Savior                   : Offline missing-word checker
#   - Bitcoin Core Tools            : Salvage, dump, rescan
#   - Balance Checker               : Multi-API blockchain queries
################################################################################

set -e

# ==================== CONFIGURATION ====================
WORK_DIR="$HOME/.crypto-recovery-suite"
TOOLS_DIR="$WORK_DIR/tools"
LOG_DIR="$WORK_DIR/logs"
OUTPUT_DIR="$WORK_DIR/output"
mkdir -p "$LOG_DIR" "$OUTPUT_DIR"

# Tool paths
BTCRECOVER_DIR="$TOOLS_DIR/btcrecover"
PYWALLET_DIR="$TOOLS_DIR/pywallet"
PY3ETHRECOVER_DIR="$TOOLS_DIR/py3ethrecover"
SEED_SCANNER_DIR="$TOOLS_DIR/seed-phrase-scanner"
METAMASK_DECRYPTOR="$TOOLS_DIR/metamask-vault-decryptor.html"
IANCOLEMAN_TOOL="$TOOLS_DIR/bip39-standalone.html"
SEED_SAVIOR="$TOOLS_DIR/seed-savior.html"

# ==================== COLORS ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ==================== UTILITIES ====================
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  _   _ _   _ ____  _____ ____  _____ _   _ ____  "
    echo " | | | | | | |  _ \| ____|  _ \| ____| \ | |  _ \ "
    echo " | | | | | | | |_) |  _| | |_) |  _| |  \| | | | |"
    echo " | |_| | |_| |  _ <| |___|  __/| |___| |\  | |_| |"
    echo "  \___/ \___/|_| \_\_____|_|   |_____|_| \_|____/ "
    echo -e "  ${MAGENTA}ULTIMATE CRYPTO RECOVERY SUITE v2.0${NC}"
    echo -e "  ${YELLOW}Working Directory: ${WORK_DIR}${NC}"
    echo ""
}

pause() {
    echo -e "\n${CYAN}Press [Enter] to continue...${NC}"
    read
}

log_cmd() {
    local cmd="$1"
    local logfile="$LOG_DIR/recovery_$(date +%Y%m%d_%H%M%S).log"
    echo -e "${CYAN}[*] Logging to: ${logfile}${NC}"
    echo "Command: $cmd" > "$logfile"
    echo "Started: $(date)" >> "$logfile"
    echo "========================================" >> "$logfile"
    eval "$cmd" 2>&1 | tee -a "$logfile"
    echo "========================================" >> "$logfile"
    echo "Finished: $(date)" >> "$logfile"
    echo -e "\n${GREEN}[+] Output saved to ${logfile}${NC}"
}

confirm_run() {
    local cmd="$1"
    echo -e "\n${YELLOW}Command to execute:${NC}"
    echo -e "${BOLD}$cmd${NC}\n"
    read -p "Run this command? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo -e "${RED}[-] Aborted by user.${NC}"
        return 1
    fi
    log_cmd "$cmd"
}

check_tool() {
    local tool_path="$1"
    local tool_name="$2"
    if [ ! -d "$tool_path" ] && [ ! -f "$tool_path" ]; then
        echo -e "${RED}[!] ${tool_name} not found at ${tool_path}${NC}"
        echo -e "${YELLOW}    Please run '1) Install/Update All Tools' first.${NC}"
        pause
        return 1
    fi
    return 0
}

# ==================== INSTALLATION ====================
install_all_tools() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Installing Ultimate Crypto Recovery Suite...${NC}\n"

    echo -e "${BLUE}[1/10] Updating system packages...${NC}"
    sudo apt-get update
    sudo apt-get install -y \
        python3 python3-pip python3-venv git build-essential \
        libssl-dev libsecp256k1-dev jq curl wget nano \
        autoconf automake libtool pkg-config swig \
        hashcat john p7zip-full libdb-dev \
        python3-bsddb3 testdisk photorec \
        || echo -e "${YELLOW}[!] Some packages already installed.${NC}"

    echo -e "${BLUE}[2/10] Installing BTCRecover (3rdIteration)...${NC}"
    if [ ! -d "$BTCRECOVER_DIR" ]; then
        git clone --recursive https://github.com/3rdIteration/btcrecover.git "$BTCRECOVER_DIR"
    else
        cd "$BTCRECOVER_DIR" && git pull && git submodule update --init --recursive
    fi
    cd "$BTCRECOVER_DIR"
    pip3 install -r requirements-full.txt --break-system-packages 2>/dev/null || pip3 install -r requirements-full.txt

    echo -e "${BLUE}[3/10] Installing PyWallet (GSC Python3 fork)...${NC}"
    if [ ! -d "$PYWALLET_DIR" ]; then
        git clone https://github.com/Great-Software-Company/pywallet.git "$PYWALLET_DIR" 2>/dev/null || \
        git clone https://github.com/jackjack-jj/pywallet.git "$PYWALLET_DIR"
    else
        cd "$PYWALLET_DIR" && git pull
    fi

    echo -e "${BLUE}[4/10] Installing py3ethrecover...${NC}"
    if [ ! -d "$PY3ETHRECOVER_DIR" ]; then
        git clone https://github.com/marsante/py3ethrecover.git "$PY3ETHRECOVER_DIR"
    else
        cd "$PY3ETHRECOVER_DIR" && git pull
    fi
    cd "$PY3ETHRECOVER_DIR"
    pip3 install -r requirements.txt --break-system-packages 2>/dev/null || pip3 install -r requirements.txt

    echo -e "${BLUE}[5/10] Installing Seed Phrase Scanner...${NC}"
    if [ ! -d "$SEED_SCANNER_DIR" ]; then
        git clone https://github.com/Arien10/seed-phrase-scanner.git "$SEED_SCANNER_DIR"
    else
        cd "$SEED_SCANNER_DIR" && git pull
    fi

    echo -e "${BLUE}[6/10] Downloading MetaMask Vault Decryptor (offline)...${NC}"
    if [ ! -f "$METAMASK_DECRYPTOR" ]; then
        wget -q "https://metamask.github.io/vault-decryptor/" -O "$METAMASK_DECRYPTOR" 2>/dev/null || \
        echo -e "${YELLOW}    [!] Could not download MetaMask decryptor. Get it manually.${NC}"
    fi

    echo -e "${BLUE}[7/10] Downloading Ian Coleman BIP39 Tool (offline)...${NC}"
    if [ ! -f "$IANCOLEMAN_TOOL" ]; then
        wget -q "https://raw.githubusercontent.com/iancoleman/bip39/master/src/index.html" \
            -O "$IANCOLEMAN_TOOL" 2>/dev/null || \
        echo -e "${YELLOW}    [!] Could not download BIP39 tool.${NC}"
    fi

    echo -e "${BLUE}[8/10] Downloading Seed Savior (offline missing word checker)...${NC}"
    if [ ! -f "$SEED_SAVIOR" ]; then
        wget -q "https://3rditeration.github.io/mnemonic-recovery/src/index.html" \
            -O "$SEED_SAVIOR" 2>/dev/null || \
        echo -e "${YELLOW}    [!] Could not download Seed Savior.${NC}"
    fi

    echo -e "${BLUE}[9/10] Checking Hashcat & John the Ripper...${NC}"
    hashcat --version 2>/dev/null || echo -e "${YELLOW}    [!] Hashcat not found. Install with: sudo apt install hashcat${NC}"
    john --version 2>/dev/null || echo -e "${YELLOW}    [!] John not found. Install with: sudo apt install john${NC}"

    echo -e "${BLUE}[10/10] Verifying BTCRecover modules...${NC}"
    cd "$BTCRECOVER_DIR"
    if python3 -c "import lib.cardano.cardano_utils" 2>/dev/null; then
        echo -e "${GREEN}    [+] All modules verified.${NC}"
    else
        echo -e "${YELLOW}    [!] Cardano module check failed. Submodules may need manual update.${NC}"
    fi

    echo -e "\n${GREEN}${BOLD}[+] Installation Complete!${NC}"
    echo -e "${CYAN}    Tools installed in: ${TOOLS_DIR}${NC}"
    echo -e "${YELLOW}    [!] ALWAYS work OFFLINE when handling real seeds/keys.${NC}"
    pause
}

# ==================== SEED RECOVERY SUBMENU ====================
seed_recovery_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${MAGENTA}--- SEED PHRASE RECOVERY ---${NC}\n"
        echo "  1) Missing Words (BTCRecover)"
        echo "  2) Scrambled Words (BTCRecover)"
        echo "  3) Wrong Words / Mismatch (BTCRecover)"
        echo "  4) BIP39 Passphrase / 25th Word (BTCRecover)"
        echo "  5) Seed Savior (Offline Missing Word Checker)"
        echo "  6) Full Auto Recovery (All Modes)"
        echo "  7) Back to Main Menu"
        echo ""
        read -rp "Choice: " choice
        case "$choice" in
            1) recover_missing_words ;;
            2) recover_scrambled_words ;;
            3) recover_mismatch_words ;;
            4) recover_bip39_passphrase ;;
            5) open_seed_savior ;;
            6) full_auto_seed_recovery ;;
            7) break ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

recover_missing_words() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Missing Words Recovery (BTCRecover)${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter seed phrase. Use '?' for unknown words:${NC}"
    read -rp "Seed: " seed
    echo -e "\n${YELLOW}Known address from wallet:${NC}"
    read -rp "Address: " addr
    echo -e "\n${YELLOW}Derivation path [m/84'/0'/0'/0]:${NC}"
    read -rp "Path: " dpath
    dpath=${dpath:-"m/84'/0'/0'/0"}

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py \
--mnemonic \"$seed\" --addrs \"$addr\" --wallet-type bip39 \
--bip32-path \"$dpath\" --addr-limit 5 --language EN \
--threads 8 --no-dupchecks --autosave \"$LOG_DIR/missing_words.save\""
    confirm_run "$cmd"
    pause
}

recover_scrambled_words() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Scrambled Words Recovery (BTCRecover)${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter ALL seed words (space-separated, any order):${NC}"
    read -rp "Words: " words
    echo -e "\n${YELLOW}Known address:${NC}"
    read -rp "Address: " addr

    local tokenfile="$LOG_DIR/scrambled_$(date +%s).txt"
    echo "$words" | tr ' ' '\n' > "$tokenfile"

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py \
--tokenlist \"$tokenfile\" --mnemonic-length 12 --language EN \
--dsw --wallet-type bip39 --addr-limit 10 --addrs \"$addr\" \
--no-dupchecks --autosave \"$LOG_DIR/scrambled.save\""
    confirm_run "$cmd"
    pause
}

recover_mismatch_words() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Wrong Words / Mismatch Recovery (BTCRecover)${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter full seed (with wrong words):${NC}"
    read -rp "Seed: " seed
    echo -e "\n${YELLOW}How many words might be wrong? [1]:${NC}"
    read -rp "Typos: " typos
    typos=${typos:-1}
    echo -e "\n${YELLOW}Known address:${NC}"
    read -rp "Address: " addr

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py \
--mnemonic \"$seed\" --addrs \"$addr\" --wallet-type bip39 \
--big-typos $typos --addr-limit 5 --language EN \
--no-dupchecks --autosave \"$LOG_DIR/mismatch.save\""
    confirm_run "$cmd"
    pause
}

recover_bip39_passphrase() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] BIP39 Passphrase (25th Word) Recovery${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter your 12/24 word seed:${NC}"
    read -rp "Seed: " seed
    echo -e "\n${YELLOW}Known address to verify:${NC}"
    read -rp "Address: " addr
    echo -e "\n${YELLOW}Tokenlist file path (password patterns):${NC}"
    read -rp "Tokenlist: " tlist

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 btcrecover.py \
--bip39 --mnemonic \"$seed\" --addrs \"$addr\" --wallet-type bip39 \
--tokenlist \"$tlist\" --autosave \"$LOG_DIR/passphrase.save\" --threads 8"
    confirm_run "$cmd"
    pause
}

open_seed_savior() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Seed Savior (Offline Missing Word Checker)${NC}\n"
    if [ ! -f "$SEED_SAVIOR" ]; then
        echo -e "${RED}[!] Seed Savior not found. Install tools first.${NC}"
        pause
        return
    fi
    echo -e "${GREEN}[+] Opening Seed Savior in browser...${NC}"
    echo -e "${YELLOW}    Disconnect internet before using with real seeds!${NC}"
    xdg-open "$SEED_SAVIOR" 2>/dev/null || firefox "$SEED_SAVIOR" 2>/dev/null || \
    echo -e "${CYAN}    File location: ${SEED_SAVIOR}${NC}"
    pause
}

full_auto_seed_recovery() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Full Auto Seed Recovery${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter seed info (use '?' for unknowns, or all words if scrambled):${NC}"
    read -rp "Seed: " seed_info
    echo -e "\n${YELLOW}Known address (or leave blank if using AddressDB):${NC}"
    read -rp "Address: " addr
    echo -e "\n${YELLOW}Address DB path (or leave blank):${NC}"
    read -rp "DB: " dbfile

    local base="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py --wallet-type bip39 --language EN --no-dupchecks --autosave \"$LOG_DIR/fullauto.save\""
    [ -n "$addr" ] && base="$base --addrs \"$addr\""
    [ -n "$dbfile" ] && base="$base --addressdb \"$dbfile\""

    if [ -z "$addr" ] && [ -z "$dbfile" ]; then
        echo -e "${RED}[!] Need at least an address or AddressDB.${NC}"
        pause
        return
    fi

    if [[ "$seed_info" == *"?"* ]]; then
        echo -e "\n${CYAN}[*] Trying MISSING WORDS...${NC}"
        confirm_run "$base --mnemonic \"$seed_info\" --addr-limit 5" || true
    fi

    echo -e "\n${CYAN}[*] Trying SCRAMBLED...${NC}"
    local tf="$LOG_DIR/auto_tokens_$(date +%s).txt"
    echo "$seed_info" | tr ' ' '\n' > "$tf"
    confirm_run "$base --tokenlist \"$tf\" --mnemonic-length 12 --addr-limit 10 --dsw" || true

    echo -e "\n${CYAN}[*] Trying MISMATCH (1 wrong word)...${NC}"
    confirm_run "$base --mnemonic \"$seed_info\" --big-typos 1 --addr-limit 5" || true

    echo -e "\n${GREEN}[+] Full auto sequence complete.${NC}"
    pause
}

# ==================== WALLET.DAT RECOVERY SUBMENU ====================
walletdat_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${MAGENTA}--- WALLET.DAT RECOVERY ---${NC}\n"
        echo "  1) PyWallet - Dump Keys & Check Balances"
        echo "  2) PyWallet - Recover from Corrupt wallet.dat"
        echo "  3) PyWallet - Scan Drive for Lost Coins"
        echo "  4) Bitcoin Core - Salvage Corrupt Wallet"
        echo "  5) Bitcoin Core - Dump Wallet (bitcoin-wallet tool)"
        echo "  6) Password Recovery - BTCRecover"
        echo "  7) Password Recovery - Hashcat (GPU)"
        echo "  8) Password Recovery - John the Ripper (CPU)"
        echo "  9) Back to Main Menu"
        echo ""
        read -rp "Choice: " choice
        case "$choice" in
            1) pywallet_dump ;;
            2) pywallet_corrupt ;;
            3) pywallet_scan_drive ;;
            4) bitcoin_core_salvage ;;
            5) bitcoin_core_dump ;;
            6) walletdat_btcrecover ;;
            7) walletdat_hashcat ;;
            8) walletdat_john ;;
            9) break ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

pywallet_dump() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] PyWallet - Dump Keys & Check Balance${NC}\n"
    check_tool "$PYWALLET_DIR/pywallet.py" "PyWallet" || return

    echo -e "${YELLOW}Enter path to wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Wallet passphrase (leave blank if unencrypted):${NC}"
    read -rsp "Passphrase: " pass
    echo ""
    local passarg=""
    [ -n "$pass" ] && passarg="--passphrase=\"$pass\""

    local out="$OUTPUT_DIR/pywallet_dump_$(date +%s).json"
    local cmd="cd \"$PYWALLET_DIR\" && python3 pywallet.py --dumpwallet --dumpwithbalance $passarg --wallet=\"$wfile\" > \"$out\""
    confirm_run "$cmd"

    echo -e "\n${GREEN}[+] Dump saved to: ${out}${NC}"
    echo -e "${YELLOW}    Check the 'sec:' field for WIF private keys.${NC}"
    pause
}

pywallet_corrupt() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] PyWallet - Recover Corrupt wallet.dat${NC}\n"
    check_tool "$PYWALLET_DIR/pywallet.py" "PyWallet" || return

    echo -e "${YELLOW}Enter path to corrupt wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Output directory for recovered wallets:${NC}"
    read -rp "Output: " outdir
    outdir=${outdir:-"$OUTPUT_DIR/recovered_wallets"}
    mkdir -p "$outdir"

    local cmd="cd \"$PYWALLET_DIR\" && python3 pywallet.py --recover --recov_device=\"$wfile\" --recov_size=10000 --recov_outputdir=\"$outdir\""
    confirm_run "$cmd"
    pause
}

pywallet_scan_drive() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] PyWallet - Scan Drive for Lost Bitcoin${NC}\n"
    check_tool "$PYWALLET_DIR/pywallet.py" "PyWallet" || return

    echo -e "${YELLOW}Enter device to scan (e.g., /dev/sda, or a disk image file):${NC}"
    read -rp "Device: " device
    echo -e "\n${YELLOW}Output directory:${NC}"
    read -rp "Output: " outdir
    outdir=${outdir:-"$OUTPUT_DIR/drive_scan"}

    local cmd="cd \"$PYWALLET_DIR\" && python3 pywallet.py --recover --recov_device=\"$device\" --recov_size=1000000 --recov_outputdir=\"$outdir\""
    confirm_run "$cmd"
    pause
}

bitcoin_core_salvage() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Bitcoin Core - Salvage Corrupt Wallet${NC}\n"
    echo -e "${YELLOW}Enter path to wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Output dump file [wallet_dump.txt]:${NC}"
    read -rp "Output: " outf
    outf=${outf:-"$OUTPUT_DIR/wallet_dump.txt"}

    if command -v bitcoin-wallet &> /dev/null; then
        local cmd="bitcoin-wallet -wallet=\"$wfile\" -dumpfile=\"$outf\" dump"
        confirm_run "$cmd"
    else
        echo -e "${RED}[!] bitcoin-wallet tool not found.${NC}"
        echo -e "${YELLOW}    Install Bitcoin Core or use PyWallet instead.${NC}"
    fi
    pause
}

bitcoin_core_dump() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Bitcoin Core - Dump Wallet${NC}\n"
    echo -e "${YELLOW}Enter path to wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Output dump file [wallet_dump.txt]:${NC}"
    read -rp "Output: " outf
    outf=${outf:-"$OUTPUT_DIR/wallet_dump.txt"}

    if command -v bitcoin-wallet &> /dev/null; then
        local cmd="bitcoin-wallet -wallet=\"$wfile\" -dumpfile=\"$outf\" dump"
        confirm_run "$cmd"
    else
        echo -e "${RED}[!] bitcoin-wallet not found. Install Bitcoin Core.${NC}"
    fi
    pause
}

walletdat_btcrecover() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] wallet.dat Password Recovery (BTCRecover)${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter path to wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Tokenlist or Passwordlist file:${NC}"
    read -rp "Wordlist: " wlist
    echo -e "\n${YELLOW}Use GPU? [y/N]:${NC}"
    read -rp "GPU: " gpu
    local gpuarg=""
    [[ "$gpu" =~ ^[Yy]$ ]] && gpuarg="--enable-gpu"

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 btcrecover.py --wallet \"$wfile\" --tokenlist \"$wlist\" $gpuarg --autosave \"$LOG_DIR/walletdat_pass.save\" --threads 8"
    confirm_run "$cmd"
    pause
}

walletdat_hashcat() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] wallet.dat Password Recovery (Hashcat GPU)${NC}\n"
    if ! command -v hashcat &> /dev/null; then
        echo -e "${RED}[!] Hashcat not installed. Run 'sudo apt install hashcat'${NC}"
        pause
        return
    fi

    echo -e "${YELLOW}Enter path to wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Output hash file [hash.txt]:${NC}"
    read -rp "Hashfile: " hfile
    hfile=${hfile:-"$OUTPUT_DIR/hash.txt"}

    # Try to use bitcoin2john from John the Ripper
    local b2j=""
    if command -v bitcoin2john.py &> /dev/null; then
        b2j="bitcoin2john.py"
    elif [ -f "/usr/share/john/bitcoin2john.py" ]; then
        b2j="/usr/share/john/bitcoin2john.py"
    elif find / -name "bitcoin2john.py" 2>/dev/null | head -1 | grep -q .; then
        b2j=$(find / -name "bitcoin2john.py" 2>/dev/null | head -1)
    else
        echo -e "${YELLOW}[!] bitcoin2john.py not found. Downloading...${NC}"
        wget -q "https://raw.githubusercontent.com/openwall/john/bleeding-jumbo/run/bitcoin2john.py" -O /tmp/bitcoin2john.py
        b2j="/tmp/bitcoin2john.py"
    fi

    echo -e "${CYAN}[*] Extracting hash with bitcoin2john...${NC}"
    python3 "$b2j" "$wfile" > "$hfile" 2>/dev/null || \
    python "$b2j" "$wfile" > "$hfile" 2>/dev/null

    if [ ! -s "$hfile" ]; then
        echo -e "${RED}[!] Failed to extract hash. Wallet may be unencrypted or incompatible.${NC}"
        pause
        return
    fi

    echo -e "${GREEN}[+] Hash extracted to: ${hfile}${NC}"
    echo -e "\n${YELLOW}Hashcat attack mode:${NC}"
    echo "  1) Dictionary attack (-a 0)"
    echo "  2) Mask/Brute force (-a 3)"
    echo "  3) Hybrid wordlist + mask (-a 6)"
    read -rp "Choice [1]: " hmode
    echo -e "\n${YELLOW}Wordlist or mask (for brute force):${NC}"
    read -rp "Input: " hinput

    local attack=""
    case "$hmode" in
        2) attack="-a 3 \"$hinput\"" ;;
        3) attack="-a 6 \"$hinput\" ?a?a?a?a" ;;
        *) attack="-a 0 \"$hinput\"" ;;
    esac

    local cmd="hashcat -m 11300 \"$hfile\" $attack -o \"$OUTPUT_DIR/hashcat_cracked.txt\" --force"
    confirm_run "$cmd"
    pause
}

walletdat_john() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] wallet.dat Password Recovery (John the Ripper CPU)${NC}\n"
    if ! command -v john &> /dev/null; then
        echo -e "${RED}[!] John not installed. Run 'sudo apt install john'${NC}"
        pause
        return
    fi

    echo -e "${YELLOW}Enter path to wallet.dat:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Output hash file [john_hash.txt]:${NC}"
    read -rp "Hashfile: " hfile
    hfile=${hfile:-"$OUTPUT_DIR/john_hash.txt"}

    local b2j=""
    if command -v bitcoin2john.py &> /dev/null; then
        b2j="bitcoin2john.py"
    elif [ -f "/usr/share/john/bitcoin2john.py" ]; then
        b2j="/usr/share/john/bitcoin2john.py"
    else
        wget -q "https://raw.githubusercontent.com/openwall/john/bleeding-jumbo/run/bitcoin2john.py" -O /tmp/bitcoin2john.py
        b2j="/tmp/bitcoin2john.py"
    fi

    python3 "$b2j" "$wfile" > "$hfile" 2>/dev/null
    if [ ! -s "$hfile" ]; then
        echo -e "${RED}[!] Hash extraction failed.${NC}"
        pause
        return
    fi

    echo -e "${GREEN}[+] Hash extracted.${NC}"
    echo -e "\n${YELLOW}Wordlist file (leave blank for default incremental):${NC}"
    read -rp "Wordlist: " wlist

    local cmd=""
    if [ -n "$wlist" ]; then
        cmd="john --wordlist=\"$wlist\" \"$hfile\""
    else
        cmd="john \"$hfile\""
    fi
    confirm_run "$cmd"
    pause
}

# ==================== ETHEREUM/METAMASK SUBMENU ====================
ethereum_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${MAGENTA}--- ETHEREUM & METAMASK RECOVERY ---${NC}\n"
        echo "  1) py3ethrecover - Keystore Password"
        echo "  2) MetaMask Vault Decryptor (Offline)"
        echo "  3) ETH Seed Recovery (BTCRecover)"
        echo "  4) Back to Main Menu"
        echo ""
        read -rp "Choice: " choice
        case "$choice" in
            1) py3ethrecover_run ;;
            2) metamask_decryptor ;;
            3) eth_seed_recovery ;;
            4) break ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

py3ethrecover_run() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] py3ethrecover - Ethereum Keystore Password${NC}\n"
    check_tool "$PY3ETHRECOVER_DIR/py3ethrecover.py" "py3ethrecover" || return

    echo -e "${YELLOW}Enter path to Ethereum keystore JSON file:${NC}"
    read -rp "Keystore: " kfile
    echo -e "\n${YELLOW}Select attack mode:${NC}"
    echo "  1) Wordlist file"
    echo "  2) Brute force (custom charset)"
    echo "  3) Brute force (full ASCII)"
    read -rp "Choice [1]: " mode

    local cmd="cd \"$PY3ETHRECOVER_DIR\" && python3 py3ethrecover.py -p \"$kfile\""
    case "$mode" in
        2)
            echo -e "\n${YELLOW}Enter charset (e.g., 1234567890 or @#!$):${NC}"
            read -rp "Charset: " charset
            echo -e "\n${YELLOW}Password length:${NC}"
            read -rp "Length: " plen
            cmd="$cmd -b \"$charset\" -d $plen"
            ;;
        3)
            echo -e "\n${YELLOW}Password length:${NC}"
            read -rp "Length: " plen
            cmd="$cmd -b ASCII -d $plen"
            ;;
        *)
            echo -e "\n${YELLOW}Wordlist file path:${NC}"
            read -rp "Wordlist: " wlist
            cmd="$cmd -w \"$wlist\""
            ;;
    esac

    echo -e "\n${YELLOW}Number of threads [8]:${NC}"
    read -rp "Threads: " threads
    threads=${threads:-8}
    cmd="$cmd -v $threads"

    confirm_run "$cmd"
    pause
}

metamask_decryptor() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] MetaMask Vault Decryptor (Offline)${NC}\n"
    if [ ! -f "$METAMASK_DECRYPTOR" ]; then
        echo -e "${RED}[!] MetaMask decryptor not found. Install tools first.${NC}"
        pause
        return
    fi
    echo -e "${GREEN}[+] Opening MetaMask Vault Decryptor...${NC}"
    echo -e "${YELLOW}    1. Disconnect from internet${NC}"
    echo -e "${YELLOW}    2. Paste your vault data (from browser storage)${NC}"
    echo -e "${YELLOW}    3. Enter your MetaMask password to decrypt${NC}"
    xdg-open "$METAMASK_DECRYPTOR" 2>/dev/null || firefox "$METAMASK_DECRYPTOR" 2>/dev/null || \
    echo -e "${CYAN}    File: ${METAMASK_DECRYPTOR}${NC}"
    pause
}

eth_seed_recovery() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] ETH Seed Recovery (BTCRecover)${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter seed phrase (use '?' for unknowns):${NC}"
    read -rp "Seed: " seed
    echo -e "\n${YELLOW}Known ETH address:${NC}"
    read -rp "Address: " addr

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py \
--mnemonic \"$seed\" --addrs \"$addr\" --wallet-type ethereum \
--addr-limit 5 --language EN --threads 8 --no-dupchecks \
--autosave \"$LOG_DIR/eth_seed.save\""
    confirm_run "$cmd"
    pause
}

# ==================== FILE SYSTEM SCANNING SUBMENU ====================
filesystem_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${MAGENTA}--- FILE SYSTEM SCANNING ---${NC}\n"
        echo "  1) Scan for Wallet Files (.dat, .json, .aes, .vault)"
        echo "  2) Scan for BIP39 Seed Phrases (Leak Detection)"
        echo "  3) Scan for Private Keys (Hex/WIF)"
        echo "  4) Back to Main Menu"
        echo ""
        read -rp "Choice: " choice
        case "$choice" in
            1) scan_wallet_files ;;
            2) scan_seed_phrases ;;
            3) scan_private_keys ;;
            4) break ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

scan_wallet_files() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Scan for Wallet Files${NC}\n"
    echo -e "${YELLOW}Enter directory to scan:${NC}"
    read -rp "Directory: " scandir
    echo -e "\n${YELLOW}Output file [wallet_files.txt]:${NC}"
    read -rp "Output: " outf
    outf=${outf:-"$OUTPUT_DIR/wallet_files.txt"}

    local cmd="find \"$scandir\" -type f \\( -name '*.dat' -o -name '*.json' -o -name '*.aes' -o -name '*.vault' -o -name '*.kdbx' -o -name '*.wallet' \\) 2>/dev/null | tee \"$outf\""
    confirm_run "$cmd"
    echo -e "\n${GREEN}[+] Results saved to: ${outf}${NC}"
    pause
}

scan_seed_phrases() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] BIP39 Seed Phrase Scanner${NC}\n"
    check_tool "$SEED_SCANNER_DIR/ULTIMATESEEDPHRASECSCANNER.py" "Seed Scanner" || return

    echo -e "${YELLOW}This tool scans files for leaked BIP39 seed phrases.${NC}"
    echo -e "${YELLOW}Enter directory to scan:${NC}"
    read -rp "Directory: " scandir

    local cmd="cd \"$SEED_SCANNER_DIR\" && python3 ULTIMATESEEDPHRASECSCANNER.py"
    confirm_run "$cmd"
    pause
}

scan_private_keys() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Scan for Private Keys${NC}\n"
    echo -e "${YELLOW}Enter directory to scan:${NC}"
    read -rp "Directory: " scandir
    echo -e "\n${YELLOW}Output file [private_keys.txt]:${NC}"
    read -rp "Output: " outf
    outf=${outf:-"$OUTPUT_DIR/private_keys.txt"}

    # Search for WIF keys (51 chars starting with 5, or 52 chars starting with K/L)
    # and hex keys (64 chars)
    local cmd="grep -r -E '(^5[HJK][1-9A-Za-z]{48,49}$)|(^[KkLl][1-9A-Za-z]{51}$)|(^[0-9a-fA-F]{64}$)' \"$scandir\" 2>/dev/null | tee \"$outf\""
    confirm_run "$cmd"
    echo -e "\n${GREEN}[+] Results saved to: ${outf}${NC}"
    pause
}

# ==================== ADDRESS & BALANCE TOOLS SUBMENU ====================
address_tools_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${MAGENTA}--- ADDRESS & BALANCE TOOLS ---${NC}\n"
        echo "  1) Generate Address Database"
        echo "  2) Derivation Path Scanner"
        echo "  3) Check Address Balance (Multi-API)"
        echo "  4) Ian Coleman BIP39 Tool (Offline)"
        echo "  5) Back to Main Menu"
        echo ""
        read -rp "Choice: " choice
        case "$choice" in
            1) generate_address_db ;;
            2) derivation_path_scan ;;
            3) check_balance ;;
            4) open_iancoleman ;;
            5) break ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

generate_address_db() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Generate Address Database${NC}\n"
    check_tool "$BTCRECOVER_DIR/create-address-db.py" "BTCRecover" || return

    echo -e "${YELLOW}Source type:${NC}"
    echo "  1) Bitcoin Core blockchain data"
    echo "  2) Address list file"
    read -rp "Choice [1]: " src

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 create-address-db.py"
    if [ "$src" == "2" ]; then
        echo -e "\n${YELLOW}Address list file path:${NC}"
        read -rp "File: " addrfile
        cmd="$cmd --inputlist \"$addrfile\""
    else
        echo -e "\n${YELLOW}Bitcoin Core datadir [/root/.bitcoin]:${NC}"
        read -rp "Datadir: " datadir
        datadir=${datadir:-/root/.bitcoin}
        cmd="$cmd --datadir \"$datadir\""
    fi

    echo -e "\n${YELLOW}DB length (2^N) [30]:${NC}"
    read -rp "DBLength: " dblen
    dblen=${dblen:-30}
    cmd="$cmd --dblength $dblen --dbfilename \"$WORK_DIR/addresses.db\""

    confirm_run "$cmd"
    pause
}

derivation_path_scan() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Derivation Path Scanner${NC}\n"
    check_tool "$BTCRECOVER_DIR/seedrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Enter recovered seed:${NC}"
    read -rp "Seed: " seed
    echo -e "\n${YELLOW}Known address:${NC}"
    read -rp "Address: " addr

    local pathfile="$LOG_DIR/common_paths_$(date +%s).txt"
    cat > "$pathfile" << 'EOF'
m/44'/0'/0'/0
m/49'/0'/0'/0
m/84'/0'/0'/0
m/86'/0'/0'/0
m/0'/0
m/44'/60'/0'/0
m/44'/2'/0'/0
EOF
    echo -e "${GREEN}[+] Common paths saved to: ${pathfile}${NC}"

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py \
--mnemonic \"$seed\" --addrs \"$addr\" --wallet-type bip39 \
--pathlist \"$pathfile\" --addr-limit 5 --no-dupchecks \
--autosave \"$LOG_DIR/path_scan.save\""
    confirm_run "$cmd"
    pause
}

check_balance() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Check Address Balance${NC}\n"
    echo -e "${YELLOW}Enter address to check:${NC}"
    read -rp "Address: " addr

    echo -e "\n${CYAN}[*] Querying multiple APIs...${NC}"
    if [[ "$addr" == bc1* ]] || [[ "$addr" == 1* ]] || [[ "$addr" == 3* ]]; then
        echo -e "\n${BLUE}--- Blockchair (BTC) ---${NC}"
        curl -s "https://api.blockchair.com/bitcoin/dashboards/address/${addr}" | \
        jq '.data."'"$addr"'".address | {balance: .balance, received: .received, txs: .transaction_count}' 2>/dev/null || echo "Failed"
        
        echo -e "\n${BLUE}--- Blockstream ---${NC}"
        curl -s "https://blockstream.info/api/address/${addr}" | \
        jq '{balance: .chain_stats.funded_txo_sum, spent: .chain_stats.spent_txo_sum, txs: .chain_stats.tx_count}' 2>/dev/null || echo "Failed"
    elif [[ "$addr" == 0x* ]]; then
        echo -e "\n${BLUE}--- Etherscan (ETH) ---${NC}"
        echo -e "${YELLOW}    (Requires API key for full data)${NC}"
        curl -s "https://api.blockchair.com/ethereum/dashboards/address/${addr}" | \
        jq '.data."'"$addr"'".address | {balance: .balance, txs: .transaction_count}' 2>/dev/null || echo "Failed"
    elif [[ "$addr" == L* ]] || [[ "$addr" == M* ]] || [[ "$addr" == ltc1* ]]; then
        echo -e "\n${BLUE}--- Blockchair (LTC) ---${NC}"
        curl -s "https://api.blockchair.com/litecoin/dashboards/address/${addr}" | \
        jq '.data."'"$addr"'".address | {balance: .balance, txs: .transaction_count}' 2>/dev/null || echo "Failed"
    else
        echo -e "${YELLOW}[!] Unknown address format. Trying generic query...${NC}"
        curl -s "https://api.blockchair.com/bitcoin/dashboards/address/${addr}" | \
        jq '.data."'"$addr"'".address | {balance: .balance}' 2>/dev/null || echo "Failed"
    fi
    pause
}

open_iancoleman() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Ian Coleman BIP39 Tool (Offline)${NC}\n"
    if [ ! -f "$IANCOLEMAN_TOOL" ]; then
        echo -e "${RED}[!] Tool not found. Install first.${NC}"
        pause
        return
    fi
    echo -e "${GREEN}[+] Opening BIP39 tool...${NC}"
    echo -e "${YELLOW}    Disconnect internet before using with real seeds!${NC}"
    xdg-open "$IANCOLEMAN_TOOL" 2>/dev/null || firefox "$IANCOLEMAN_TOOL" 2>/dev/null || \
    echo -e "${CYAN}    File: ${IANCOLEMAN_TOOL}${NC}"
    pause
}

# ==================== OTHER WALLETS SUBMENU ====================
other_wallets_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${MAGENTA}--- OTHER WALLET TYPES ---${NC}\n"
        echo "  1) Electrum Password / Seed Recovery"
        echo "  2) Blockchain.com Password Recovery"
        echo "  3) MultiBit HD / Classic"
        echo "  4) Android Wallet PIN"
        echo "  5) Back to Main Menu"
        echo ""
        read -rp "Choice: " choice
        case "$choice" in
            1) electrum_recovery ;;
            2) blockchain_recovery ;;
            3) multibit_recovery ;;
            4) android_pin_recovery ;;
            5) break ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

electrum_recovery() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Electrum Recovery${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Select mode:${NC}"
    echo "  1) Electrum Password (wallet file)"
    echo "  2) Electrum Seed (missing words)"
    read -rp "Choice [1]: " mode

    if [ "$mode" == "2" ]; then
        echo -e "\n${YELLOW}Enter seed (use '?' for unknowns):${NC}"
        read -rp "Seed: " seed
        echo -e "\n${YELLOW}Known address:${NC}"
        read -rp "Address: " addr
        local cmd="cd \"$BTCRECOVER_DIR\" && python3 seedrecover.py \
--mnemonic \"$seed\" --addrs \"$addr\" --wallet-type electrum2 \
--addr-limit 5 --no-dupchecks --autosave \"$LOG_DIR/electrum_seed.save\""
        confirm_run "$cmd"
    else
        echo -e "\n${YELLOW}Path to Electrum wallet file:${NC}"
        read -rp "Wallet: " wfile
        echo -e "\n${YELLOW}Tokenlist file:${NC}"
        read -rp "Tokenlist: " tlist
        local cmd="cd \"$BTCRECOVER_DIR\" && python3 btcrecover.py \
--wallet \"$wfile\" --tokenlist \"$tlist\" --autosave \"$LOG_DIR/electrum_pass.save\""
        confirm_run "$cmd"
    fi
    pause
}

blockchain_recovery() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Blockchain.com Password Recovery${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Path to wallet.aes.json (or use download script):${NC}"
    read -rp "Wallet: " wfile
    if [ ! -f "$wfile" ]; then
        echo -e "${YELLOW}[!] File not found. Download using:${NC}"
        echo -e "${CYAN}    cd $BTCRECOVER_DIR/extract-scripts && python3 download-blockchain-wallet.py${NC}"
        pause
        return
    fi
    echo -e "\n${YELLOW}Tokenlist or Passwordlist:${NC}"
    read -rp "Wordlist: " wlist

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 btcrecover.py \
--wallet \"$wfile\" --tokenlist \"$wlist\" --autosave \"$LOG_DIR/blockchain.save\""
    confirm_run "$cmd"
    pause
}

multibit_recovery() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] MultiBit Recovery${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Select MultiBit version:${NC}"
    echo "  1) MultiBit Classic (.wallet file)"
    echo "  2) MultiBit HD (mbhd.wallet.aes)"
    read -rp "Choice [1]: " ver

    echo -e "\n${YELLOW}Wallet file path:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Tokenlist file:${NC}"
    read -rp "Tokenlist: " tlist

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 btcrecover.py \
--wallet \"$wfile\" --tokenlist \"$tlist\" --autosave \"$LOG_DIR/multibit.save\""
    confirm_run "$cmd"
    pause
}

android_pin_recovery() {
    print_banner
    echo -e "${CYAN}${BOLD}[*] Android Wallet PIN Recovery${NC}\n"
    check_tool "$BTCRECOVER_DIR/btcrecover.py" "BTCRecover" || return

    echo -e "${YELLOW}Path to Android wallet backup:${NC}"
    read -rp "Wallet: " wfile
    echo -e "\n${YELLOW}Max PIN to try [9999]:${NC}"
    read -rp "Max: " maxpin
    maxpin=${maxpin:-9999}

    local cmd="cd \"$BTCRECOVER_DIR\" && python3 btcrecover.py \
--wallet \"$wfile\" --android-pin --tokenlist <(seq 1 $maxpin) \
--autosave \"$LOG_DIR/android_pin.save\""
    confirm_run "$cmd"
    pause
}

# ==================== MAIN MENU ====================
main_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}Choose a category:${NC}\n"
        echo -e "  ${GREEN}1)${NC} Install / Update All Tools"
        echo -e "  ${GREEN}2)${NC} ${MAGENTA}Seed Phrase Recovery${NC}"
        echo -e "  ${GREEN}3)${NC} ${MAGENTA}wallet.dat Recovery${NC}"
        echo -e "  ${GREEN}4)${NC} ${MAGENTA}Ethereum & MetaMask Recovery${NC}"
        echo -e "  ${GREEN}5)${NC} ${MAGENTA}File System Scanning${NC}"
        echo -e "  ${GREEN}6)${NC} ${MAGENTA}Address & Balance Tools${NC}"
        echo -e "  ${GREEN}7)${NC} ${MAGENTA}Other Wallet Types${NC}"
        echo -e "  ${RED}0)${NC} Exit"
        echo ""
        read -rp "Choice: " choice

        case "$choice" in
            1) install_all_tools ;;
            2) seed_recovery_menu ;;
            3) walletdat_menu ;;
            4) ethereum_menu ;;
            5) filesystem_menu ;;
            6) address_tools_menu ;;
            7) other_wallets_menu ;;
            0) echo -e "\n${GREEN}[+] Stay safe. Work offline.${NC}"; exit 0 ;;
            *) echo -e "${RED}[!] Invalid choice.${NC}"; sleep 1 ;;
        esac
    done
}

# ==================== ENTRY POINT ====================
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}[!] Running as root. Not recommended for crypto ops.${NC}"
    sleep 1
fi

main_menu
