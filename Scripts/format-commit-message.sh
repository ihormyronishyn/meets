#!/usr/bin/env bash

# Keeps commit messages in the conventional style.
# Applies safe automatic cleanup where possible and rejects
# messages that still do not match the expected format.
# Merge, revert, fixup, and squash commits are left unchanged.

# It automatically trims spare whitespace, lowers
# the type word, maps common synonyms of that word onto the fixed set,
# lowers the scope, lowers an ordinary capitalised word at the start of the
# description while leaving short forms and type names alone, removes a
# trailing full stop from the description, and makes sure one empty line
# separates the summary from the body.

set -uo pipefail

MESSAGE_FILE="${1:-}"
[[ -n "$MESSAGE_FILE" && -f "$MESSAGE_FILE" ]] || exit 0

subject_line() {
  grep -vE '^[[:space:]]*#' "$MESSAGE_FILE" | sed '/^[[:space:]]*$/d' | head -n 1
}

SUBJECT="$(subject_line)"

if [[ -z "$SUBJECT" ]]; then
  echo "Commit rejected, the message is empty." >&2
  exit 1
fi

# Leave the special commits alone.
case "$SUBJECT" in
  "Merge "* | "Revert "* | "fixup! "* | "squash! "*) exit 0 ;;
esac

# The required shape. A type word, an optional scope, a description.
TYPES='build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test'
PATTERN="^(${TYPES})(\([a-z0-9._/-]+\))?(!)?: .+[^.[:space:]]$"

# The longest a summary line should be. Kept in one place so the check and
# the guidance shown to the author never drift apart.
MAX_SUMMARY_LENGTH=72

# First stage. The cheap, predictable cleanup of the summary line.
normalize() {
  local subject prefix rest bang scope type first_word
  subject="$(printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

  [[ "$subject" == *:* ]] || { printf '%s' "$subject"; return; }

  prefix="${subject%%:*}"
  rest="${subject#*:}"

  # Trim spare whitespace and a trailing full stop from the description.
  rest="$(printf '%s' "$rest" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/\.+$//')"

  # The convention asks for a description that opens in lower case. Only an
  # ordinary capitalised word is lowered. A word carrying capitals of its
  # own, such as a short form or the name of a type, is left exactly as it
  # was written, because lowering its first letter would corrupt it.
  first_word="${rest%% *}"
  if [[ "$first_word" =~ ^[A-Z][a-z]+$ ]]; then
    rest="$(printf '%s' "${rest:0:1}" | tr '[:upper:]' '[:lower:]')${rest:1}"
  fi

  bang=""
  if [[ "$prefix" == *"!" ]]; then
    bang="!"
    prefix="${prefix%!}"
  fi

  scope=""
  if [[ "$prefix" == *"("*")"* ]]; then
    scope="(${prefix#*\(}"
    prefix="${prefix%%\(*}"
  fi

  # Lower the type word and map its common synonyms onto the fixed set.
  type="$(printf '%s' "$prefix" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  case "$type" in
    feature | features) type="feat" ;;
    bugfix | bug | hotfix) type="fix" ;;
    doc) type="docs" ;;
    tests | testing) type="test" ;;
    refactoring) type="refactor" ;;
    cleanup) type="chore" ;;
  esac

  scope="$(printf '%s' "$scope" | tr '[:upper:]' '[:lower:]')"

  printf '%s%s%s: %s' "$type" "$scope" "$bang" "$rest"
}

replace_subject() {
  local new_subject tmp
  new_subject="$1"
  tmp="$(mktemp)"
  awk -v ns="$new_subject" '
    BEGIN { done = 0 }
    {
      if (!done && $0 !~ /^[[:space:]]*#/ && $0 !~ /^[[:space:]]*$/) {
        print ns
        done = 1
      } else {
        print
      }
    }
  ' "$MESSAGE_FILE" >"$tmp" && mv "$tmp" "$MESSAGE_FILE"
}

# Make sure one empty line separates the summary from the body. The summary is
# found the same way it is everywhere else, the first line that is neither a
# comment nor blank, so a template that opens with comment lines is handled as
# well as a bare message. A blank is inserted only when a body follows straight
# after, a comment or an existing blank on the next line is left as it stands.
ensure_blank_line() {
  local tmp
  tmp="$(mktemp)"
  awk '
    !done && $0 !~ /^[[:space:]]*#/ && $0 !~ /^[[:space:]]*$/ {
      print
      done = 1
      if ((getline nextline) > 0) {
        if (nextline !~ /^[[:space:]]*#/ && nextline !~ /^[[:space:]]*$/) print ""
        print nextline
      }
      next
    }
    { print }
  ' "$MESSAGE_FILE" >"$tmp" && mv "$tmp" "$MESSAGE_FILE"
}

CANDIDATE="$(normalize "$SUBJECT")"

if [[ "$CANDIDATE" =~ $PATTERN ]]; then
  if [[ "$CANDIDATE" != "$SUBJECT" ]]; then
    replace_subject "$CANDIDATE"
    echo "Commit message summary adjusted to $CANDIDATE." >&2
  fi
  ensure_blank_line
  if ((${#CANDIDATE} > MAX_SUMMARY_LENGTH)); then
    echo "Warning, the summary is ${#CANDIDATE} characters, aim for $MAX_SUMMARY_LENGTH or fewer." >&2
  fi
  exit 0
fi

# Second stage. Refuse the message and show the shape it needs to take.
echo 'Commit stopped, the message does not follow conventional style.' >&2

cat >&2 <<GUIDE

A lowercase type word opens the summary, an optional scope in round brackets can follow, then a short description with no trailing full stop, at most $MAX_SUMMARY_LENGTH characters.

build | chore | ci | docs | feat | fix | perf | refactor | revert | style | test

<type>([optional scope]): <description>

[optional body]

[optional footer(s)]

GUIDE
exit 1
