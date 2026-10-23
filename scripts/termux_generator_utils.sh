portable_sed_i() {
    if sed v </dev/null 2> /dev/null; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

apply_patches() {
    local srcdir=$(realpath "$1")
    local targetdir=$(realpath "$2")
    local patches=$(find "$srcdir" -type f | sort)

    pushd "$targetdir"

    for patch in $patches; do
        patch -p1 < "$patch"
    done

    # patch(1) leaves the pre-patch original behind as "<file>.orig" whenever
    # a hunk applies with an offset or fuzz (which routinely happens when a
    # base patch touches a file an earlier plugin patch already shifted).
    # Nothing in this generator reads those backups, and under an Android
    # res/ directory they are fatal: the resource merger rejects any file
    # whose name does not end with .xml (this killed the v4 app build at
    # :app:mergeDebugResources over activity_termux.xml.orig). Remove them
    # so the patched tree always stays buildable.
    find . -type f -name "*.orig" -delete

    # A leftover ".rej" file means a hunk did not apply at all. Never
    # continue with a half-patched tree - fail loudly instead.
    local rejects=$(find . -type f -name "*.rej")
    if [[ -n "$rejects" ]]; then
        echo "ERROR: patch rejects left behind in $targetdir:" >&2
        echo "$rejects" >&2
        popd
        return 1
    fi

    popd
}

replace_termux_name() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local targetdir="$1"
    local replacement_name="$2"
    local replacement_name_underscore="$(echo "$replacement_name" | tr . _)"
    local replacement_name_slash="$(echo "$replacement_name" | tr . /)"

    pushd "$targetdir"

    # Nur Textdateien bearbeiten, um Fehler zu vermeiden
    local file
    find . -type f -exec file {} + | grep "text" | cut -d: -f1 | while read -r file; do
        portable_sed_i -e "s|>Termux<|>$replacement_name<|g" \
                       -e "s|\"Termux\"|\"$replacement_name\"|g" \
                       -e "s|Termux:|$replacement_name:|g" \
                       -e "s|com\.termux|$replacement_name|g" \
                       -e "s|com_termux|$replacement_name_underscore|g" \
                       -e '/http/!s|com/termux|'$replacement_name_slash'|g' "$file"
    done

    popd
}

replace_termux_user_path() {
    # Default /data/data when unset (e.g. inside the bootstrap docker build
    # where the variable is not exported and `set -u` is active).
    if [[ "${TERMUX_APP__USER_PATH:-/data/data}" == "/data/data" ]]; then
        return
    fi
    local targetdir="$1"
    local replacement_path="$2"

    pushd "$targetdir"

    local file
    find . -type f -exec file {} + | grep "text" | cut -d: -f1 | while read -r file; do
        portable_sed_i -e "s|/data/data|$replacement_path|g" "$file"
    done

    popd
}

# Funktion, um Ordner zu migrieren
migrate_termux_folder() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local parentdir="$(dirname "$(dirname "$1")")"
    local replacement_name="$2"
    local destination="${parentdir}/$(echo "$replacement_name" | tr . /)/"

    echo "Migrating folder:"
    echo "- ${parentdir}/com/termux/"
    echo "to"
    echo "+ ${destination}"
    mkdir -p "${destination}"
    mv "${parentdir}/com/termux/"* "${destination}"
    rm -r "${parentdir}/com/termux/"
}

migrate_termux_folder_tree() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local targetdir="$1"
    local replacement_name="$2"

    pushd "$targetdir"

    # Vollständig macOS-kompatible Variante für Verzeichnismigration
    local dir
    find "$(pwd)" -type d -name termux | grep -v -e 'shared/termux' -e 'settings/termux' | while read -r dir; do
        migrate_termux_folder "$dir" "$replacement_name"
    done

    popd
}
