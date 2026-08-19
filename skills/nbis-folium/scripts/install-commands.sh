#!/usr/bin/env sh
# Install /folium-site and /folium-page into whichever agents are present.
#
# Skills are portable; slash commands are not. `npx skills add` copies this
# skill directory but cannot know where each agent keeps its commands, so this
# script copies the two thin wrappers in ../commands/ into the right places.
# The wrappers hold no procedure of their own -- they just preselect a template
# and defer to SKILL.md -- so there is only ever one copy of the steps.
set -eu

usage() {
  cat <<'EOF'
Usage: install-commands.sh [--scope user|project] [--dry-run] [--agent <name>]

  --scope user     install for the current user (default)
  --scope project  install into ./.claude and ./.opencode of the current project
  --agent <name>   only this agent: claude, opencode, or codex (repeatable)
  --dry-run        print what would be copied, change nothing
  -h, --help       show this help

Command formats differ per agent. This is verified for Claude Code; the
opencode and Codex paths follow their documented layouts. If a target directory
does not exist the agent is skipped, so this is safe to run anywhere.
EOF
}

scope=user
dry_run=false
agents=""

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) [ $# -ge 2 ] || { echo "--scope needs a value" >&2; exit 2; }
             case "$2" in user|project) scope=$2 ;; *) echo "bad --scope: $2" >&2; exit 2 ;; esac
             shift 2 ;;
    --agent) [ $# -ge 2 ] || { echo "--agent needs a value" >&2; exit 2; }
             case "$2" in claude|opencode|codex) ;; *) echo "bad --agent: $2" >&2; exit 2 ;; esac
             agents="$agents $2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

skill_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# The two wrappers are themselves skills, installed alongside this one. Agents
# that expose skills as slash commands already show /folium-site and
# /folium-page, so this script is only for agents that need real command files.
# Reading their SKILL.md directly keeps a single source of truth.
src=$(dirname -- "$skill_dir")
for name in folium-site folium-page; do
  if [ ! -f "$src/$name/SKILL.md" ]; then
    echo "Cannot find the $name skill next to this one ($src/$name/SKILL.md)." >&2
    echo "Install the whole package so all three skills are present:" >&2
    echo "  npx skills add pyrevo/nbis-folium-skill --skill '*'" >&2
    exit 1
  fi
done

wants() {
  [ -z "$agents" ] && return 0
  for a in $agents; do [ "$a" = "$1" ] && return 0; done
  return 1
}

installed=0

install_into() {
  agent=$1
  dest=$2
  wants "$agent" || return 0
  # Only install where the agent already lives, so running this never
  # scatters directories for tools the user does not have.
  parent=$(dirname -- "$dest")
  if [ ! -d "$parent" ]; then
    echo "skip $agent (no $parent)"
    return 0
  fi
  if [ "$dry_run" = true ]; then
    echo "would install into $dest"
    installed=$((installed + 1))
    return 0
  fi
  mkdir -p "$dest"
  for name in folium-site folium-page; do
    cp "$src/$name/SKILL.md" "$dest/$name.md"
  done
  echo "installed /folium-site and /folium-page into $dest"
  installed=$((installed + 1))
}

if [ "$scope" = project ]; then
  install_into claude   "$PWD/.claude/commands"
  install_into opencode "$PWD/.opencode/command"
else
  install_into claude   "$HOME/.claude/commands"
  install_into opencode "$HOME/.config/opencode/command"
  install_into codex    "$HOME/.codex/prompts"
fi

if [ "$installed" -eq 0 ]; then
  echo ""
  echo "No agent directories found, so nothing was installed."
  echo "Copy the two files yourself to wherever your agent keeps commands:"
  echo "  $src/folium-site/SKILL.md  -> folium-site.md"
  echo "  $src/folium-page/SKILL.md  -> folium-page.md"
  exit 1
fi

echo ""
echo "Restart or reload your agent, then type /folium-site or /folium-page."
