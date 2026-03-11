#!/bin/bash
echo "============================================"
echo "DAILY SECURITY LOG SUMMARY - $(date)"
echo "============================================"

echo ""
echo "[+] FAILED SSH ATTEMPTS (last 24h):"
sudo grep "Failed password" /var/log/auth.log | \
  grep "$(date +%b\ %e)" | wc -l

echo ""
echo "[+] SUCCESSFUL LOGINS (last 24h):"
sudo grep "Accepted" /var/log/auth.log | \
  grep "$(date +%b\ %e)" | tail -5

echo ""
echo "[+] SUDO COMMANDS (last 24h):"
sudo grep "sudo" /var/log/auth.log | \
  grep "$(date +%b\ %e)" | grep "COMMAND" | tail -10

echo ""
echo "[+] PACKAGES INSTALLED TODAY:"
grep "$(date +%Y-%m-%d)" /var/log/dpkg.log | \
  grep " install " | awk '{print $4}' | head -10

echo ""
echo "[+] LISTENING SERVICES:"
sudo ss -tlnp | grep LISTEN

echo ""
echo "[+] ACTIVE NETWORK CONNECTIONS:"
sudo ss -tnp state established

echo "============================================"
echo "END OF REPORT"
echo "============================================"
