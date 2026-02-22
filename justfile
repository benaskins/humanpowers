# Generic Claude Code Skills
# Symlinked to ~/.claude/skills/ for global availability

# List all available recipes
default:
    @just --list

# Symlink skills to ~/.claude/skills/ for global availability
install-skills:
    mkdir -p ~/.claude/skills
    for dir in skills/*/; do \
        name=$(basename "$dir"); \
        ln -sfn "$(pwd)/$dir" "$HOME/.claude/skills/$name"; \
    done
    @echo "Installed $(ls -1 skills/ | wc -l | tr -d ' ') skill(s) to ~/.claude/skills/"
