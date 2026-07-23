#!/usr/bin/env bash
# Create a cscui project from a scaffold template.
# The command is deliberately non-destructive: an existing project directory
# is rejected and all source paths are resolved relative to this script.
set -Eeuo pipefail

on_error() {
    local status=$?
    printf '[cscui] error: command failed (status %s)\n' "$status" >&2
    exit "$status"
}
trap on_error ERR

usage() {
    cat <<'USAGE'
Usage: New-CscuiProject.sh [options]

Options:
  -n, --name NAME             Project name (letters, digits, '-' or '_')
  -d, --destination DIR       Parent directory for the new project
  -t, --template NAME         Scaffold template name
  -N, --non-interactive       Never prompt; defaults are used where possible
  -h, --help                  Show this help
USAGE
}

die() {
    printf '[cscui] error: %s\n' "$1" >&2
    exit 1
}

NAME=''
DESTINATION=''
TEMPLATE=''
NON_INTERACTIVE=0

while (($# > 0)); do
    case "$1" in
        -n|--name)
            (($# >= 2)) || die "missing value for $1"
            NAME=$2
            shift 2
            ;;
        -d|--destination)
            (($# >= 2)) || die "missing value for $1"
            DESTINATION=$2
            shift 2
            ;;
        -t|--template)
            (($# >= 2)) || die "missing value for $1"
            TEMPLATE=$2
            shift 2
            ;;
        -N|--non-interactive)
            NON_INTERACTIVE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option '$1' (use --help for usage)"
            ;;
    esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
TEMPLATES_PATH="$REPO_ROOT/scaffold/templates"
[[ -d "$TEMPLATES_PATH" ]] || die "templates directory not found: $TEMPLATES_PATH"

case "${CI:-}" in
    1|true|TRUE|yes|YES) NON_INTERACTIVE=1 ;;
esac

TEMPLATES=()
for template_path in "$TEMPLATES_PATH"/*; do
    [[ -d "$template_path" ]] || continue
    TEMPLATES+=("$(basename -- "$template_path")")
done
[[ ${#TEMPLATES[@]} -gt 0 ]] || die "no templates found in $TEMPLATES_PATH"
IFS=$'\n' TEMPLATES=($(printf '%s\n' "${TEMPLATES[@]}" | LC_ALL=C sort))
unset IFS

if [[ -z "$NAME" ]]; then
    if ((NON_INTERACTIVE)); then
        die "--name is required in non-interactive mode"
    fi
    read -r -p 'Project name (required): ' NAME
fi
[[ "$NAME" =~ ^[A-Za-z][A-Za-z0-9_-]{0,63}$ ]] ||
    die 'project name must start with a letter and contain only letters, digits, hyphens, or underscores (1-64 characters)'

DEFAULT_DEST="$(dirname -- "$REPO_ROOT")"
if [[ -z "$DESTINATION" ]]; then
    if ((NON_INTERACTIVE)); then
        DESTINATION=$DEFAULT_DEST
    else
        read -r -p "Destination directory (default: $DEFAULT_DEST): " input_destination
        DESTINATION=${input_destination:-$DEFAULT_DEST}
    fi
fi
[[ -n "$DESTINATION" ]] || die 'destination directory cannot be empty'
mkdir -p -- "$DESTINATION"
DESTINATION="$(cd -- "$DESTINATION" && pwd -P)"

if [[ -z "$TEMPLATE" ]]; then
    if ((NON_INTERACTIVE)); then
        TEMPLATE=${TEMPLATES[0]}
    else
        printf 'Available templates:\n'
        for index in "${!TEMPLATES[@]}"; do
            printf '[%d] %s\n' "$((index + 1))" "${TEMPLATES[$index]}"
        done
        read -r -p 'Template number or name (default: 1): ' template_choice
        if [[ -z "$template_choice" ]]; then
            TEMPLATE=${TEMPLATES[0]}
        elif [[ "$template_choice" =~ ^[0-9]+$ ]] &&
             ((template_choice >= 1 && template_choice <= ${#TEMPLATES[@]})); then
            TEMPLATE=${TEMPLATES[$((template_choice - 1))]}
        else
            TEMPLATE=$template_choice
        fi
    fi
fi

template_is_known=0
for known_template in "${TEMPLATES[@]}"; do
    [[ "$known_template" == "$TEMPLATE" ]] && template_is_known=1
done
((template_is_known)) || die "unknown template '$TEMPLATE'"
TEMPLATE_ROOT="$TEMPLATES_PATH/$TEMPLATE"

NEW_PROJECT_DIR="$DESTINATION/$NAME"
[[ ! -e "$NEW_PROJECT_DIR" ]] || die "destination already exists: $NEW_PROJECT_DIR"
mkdir -- "$NEW_PROJECT_DIR"

printf '[cscui] copying %s template...\n' "$TEMPLATE"
cp -a -- "$TEMPLATE_ROOT/." "$NEW_PROJECT_DIR/"

replace_in_file() {
    local file=$1
    local token=$2
    local value=$3
    [[ -f "$file" ]] || return 0
    local pattern
    case "$token" in
        '__PROJECT_NAME__'|'{{PROJECT_NAME}}') pattern=$token ;;
        *) die "unsupported replacement token '$token'" ;;
    esac
    # Project names are restricted above, so the fixed sed expression cannot
    # be used to inject a command or a replacement expression.
    local temporary_file="${file}.cscui-tmp"
    LC_ALL=C sed "s|$pattern|$value|g" "$file" > "$temporary_file"
    mv -f -- "$temporary_file" "$file"
}

replace_in_file "$NEW_PROJECT_DIR/CMakeLists.txt" '__PROJECT_NAME__' "$NAME"
replace_in_file "$NEW_PROJECT_DIR/main.cpp" '__PROJECT_NAME__' "$NAME"
replace_in_file "$NEW_PROJECT_DIR/Main.qml" '{{PROJECT_NAME}}' "$NAME"
replace_in_file "$NEW_PROJECT_DIR/package.bat" '{{PROJECT_NAME}}' "$NAME"

[[ -d "$REPO_ROOT/components" ]] || die "components directory not found: $REPO_ROOT/components"
[[ -d "$REPO_ROOT/fonts" ]] || die "fonts directory not found: $REPO_ROOT/fonts"
[[ -f "$REPO_ROOT/src.qrc" ]] || die "resource manifest not found: $REPO_ROOT/src.qrc"
mkdir -p -- "$NEW_PROJECT_DIR/components" "$NEW_PROJECT_DIR/fonts"
cp -a -- "$REPO_ROOT/components/." "$NEW_PROJECT_DIR/components/"
cp -a -- "$REPO_ROOT/fonts/." "$NEW_PROJECT_DIR/fonts/"
cp -- "$REPO_ROOT/src.qrc" "$NEW_PROJECT_DIR/src.qrc"

printf '\nProject generated: %s\n' "$NEW_PROJECT_DIR"
printf 'Configure: cmake -S "%s" -B "%s/build"\n' "$NEW_PROJECT_DIR" "$NEW_PROJECT_DIR"
printf 'Build:     cmake --build "%s/build"\n' "$NEW_PROJECT_DIR"
printf 'Template:  %s\n' "$TEMPLATE"
