mkdir -p /home/agent/.bashrc.d
cat > /home/agent/.bashrc.d/mise.sh <<'EOF'
eval "$(mise activate bash)"
EOF
