#!/bin/bash
# Snippet Manager in Bash

# TODO: add notification for Mac:
##  osascript -e 'display notification "Build finished" with title "CI" subtitle "Success"'
## or terminal-notifier


# if [[ "$(uname -s)" == "Darwin" ]]; then
#   echo "Running on macOS"
# elif [[ "$(uname -s)" == "Linux" ]]; then
#   echo "Running on Linux"
# fi


SNIP_DIR="$HOME/.snip"
SNIP_CONFIG="$HOME/.snip/.env"
SNIPPETS_DIR="$SNIP_DIR/snippets"
SNIP_GPG_ID_FILEPATH="$SNIP_DIR/.gpgid"

if [ ! -e "$SNIPPETS_DIR" ]; then
    echo "[i] \"$SNIPPETS_DIR\" doesn't exists. Creating it..."
    mkdir -p "$SNIPPETS_DIR"

    touch "$SNIP_CONFIG"

    echo "EDITOR=vim" > "$SNIP_CONFIG"
fi

# Read dotenv
set -o allexport
source $SNIP_CONFIG
set +o allexport

cmds=(
"help"
"add"
"edit"
"del"
"list"
"search"
"show"
"raw"
"run"
"share"
"sync"
"config"
"runrofi"
"gpg_id"
"encrypt"
"decrypt"
)

alss=(
"h" #help
"a" #add
"e" #edit
"d" #del
"ls" #list
"fzf" #search
"s" #show
"rw" #raw - don't parse variables
"r" #run snippet
"shr" #share
"u" #sync
"c" #config
"rf" #rofi
"gi" #gpg-id
"enc"
"dec"
)

msgs=(
"Print this help"
"add snippet <snippet_path>"
"edit snippet <snippet_path>"
"del snippet <snippet_path>"
"list snippets [<optional_snippets_folder>]"
"search snippet (requires fzf and bat): Additional args (default is show) -> -e|--edit or -s|--show or -d|--delete"
"show <snippet_path> [--raw] | Print snippet in the terminal; if contains variable asks user for values. With --raw flag skip var parsing."
"raw <snippet_path> | Shortcut for show <snippet_path> --raw"
"run <snippet_path> | Run the snippet in a safe way, ask before run; if contains variable asks user for values"
"share|shr <snippet_path> (get a share link, similar to pastebin)"
"sync and push with git repository"
"config show and set config vars <varname>"
"run rofi (requires rofi)"
"gpg_id set gpg-id to encrypt / unencrypt"
"encrypt a snippet using gpg_id in $SNIP_GPG_ID_FILEPATH"
"decrypt a snippet using gpg_id in $SNIP_GPG_ID_FILEPATH"
)

COUNT=${#cmds[@]}

abort() {
    if [ -n "$(which gum)" ]; then
        gum log --level error $1
    else
        echo -e "[!] $1"
    fi

    exit 1
}

print() {
    echo -e "$1"
}

add() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"
    filename=""

    isValid="$(echo "$snippet_path" | grep /)"

    if [ -n "$isValid" ]; then
        filename=$(basename "$snippet_path")
        snippet_path=$(dirname "$snippet_path")

        if [ ! -e "$snippet_path" ]; then
            echo "[i] Creating \"$snippet_path\""

            mkdir -p "$snippet_path"
        fi
    fi

    snippet_path="$snippet_path/$filename"

    touch "$snippet_path"

    edit "$1"
}

encrypt() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"
    filename=""

    isValid="$(echo "$snippet_path" | grep /)"

    if [ -n "$isValid" ]; then
        filename=$(basename "$snippet_path")
        snippet_path=$(dirname "$snippet_path")

        if [ ! -e "$snippet_path" ]; then
            abort "$snippet_path doesn't exists... aborting..."
        fi
    fi

    snipper_dir="$snippet_path"
    snippet_path="$snippet_path/$filename"
    gpgId="$(cat $SNIP_GPG_ID_FILEPATH | tr -d '\n' | tr -d ' ')"

    cd "$snipper_dir"

    gpg -e -r "$gpgId" $filename

    rm "$filename"
}

decrypt() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"
    filename=""

    isValid="$(echo "$snippet_path" | grep /)"

    if [ -n "$isValid" ]; then
        filename=$(basename "$snippet_path")
        snippet_path=$(dirname "$snippet_path")

        if [ ! -e "$snippet_path" ]; then
            abort "$snippet_path doesn't exists... aborting..."
        fi
    fi


    if [ -e "$snippet_path/$filename" ]; then
        abort "$snippet_path/$filename is not encrypted... aborting..."
    fi

    snippet_path="$snippet_path/$filename.gpg"

    if [ ! -e "$snippet_path" ]; then
        abort "$snippet_path doesn't exists... aborting..."
    fi

    gpgId="$(cat $SNIP_GPG_ID_FILEPATH | tr -d '\n' | tr -d ' ')"

    gpg -q -d -u "$gpgId" "$snippet_path"
}

edit() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"

    if [ ! -e "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists. Exiting ..."
    fi

    $EDITOR "$snippet_path"
}

del() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"

    if [ ! -e "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists. Exiting ..."
    fi

    if [ -d "$snippet_path" ]; then
        echo "⚠️ \"$snippet_path\" is a directory containing multiple snippets..."

        if gum confirm "Confirm deletion ?"; then
            rm -rdf "$snippet_path"
        else
            echo "Abort"
        fi

        exit
    fi

    rm "$snippet_path"

    echo "[*] Deleted \"$snippet_path\""
}

list() {
    snippet_path="$SNIPPETS_DIR/$1"

    if [ ! -d "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists or it is a file. Exiting ..."
    fi

    tree "$snippet_path"
}

search() {
    snippet_path="$SNIPPETS_DIR"

    if [ ! -e "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists. Exiting ..."
    fi

    action="$1"

    if echo "$action" | grep -v '^--' > /dev/null; then
        search_term="$action"

        if [ -n "$search_term" ]; then
            find "$snippet_path" -type f | grep "$search_term" | sed -e "s#$SNIPPETS_DIR/##g"

            exit;
        fi
    fi

    if [ -z "$action" ]; then
        action="--show"
    fi

    snippet_path="$SNIPPETS_DIR/$(find "$snippet_path" -type f | sed -e "s#$SNIPPETS_DIR/##g" | fzf --preview "bat --color=always --style=numbers --line-range=:500 {}")"

    if [ "$action" == "-e" ] || [ "$action" == "--edit" ]; then
        "$EDITOR" "$snippet_path"
    elif [ "$action" == "-s" ] || [ "$action" == "--show" ]; then
        bat --color=always -p "$snippet_path" -p
    elif [ "$action" == "-d" ] || [ "$action" == "--delete" ]; then
        rm "$snippet_path"
    fi
}

show() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"

    if [ -e "$snippet_path.gpg" ]; then
        snippet_path="$snippet_path.gpg"
    fi

    if [ -d "$snippet_path" ]; then
        snippet_path=$(find "$snippet_path" -type f | fzf --delimiter / --with-nth -1 --height=40% --preview "bat --color=always --style=numbers --line-range=:500 {}")

        if [ -z "$snippet_path" ]; then
            exit
        fi
    fi

    if [ ! -f "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists or is a directory. Exiting ..."
    fi

    snippet=""

    if [[ "$snippet_path" == *.gpg ]]; then
        snippet=$(decrypt "$1")
    else
        snippet=$(cat "$snippet_path")
    fi

    if [ -n "$2" ]; then
        if [[ "$2" == "--raw" ]]; then
            echo "$snippet" | bat --color=always -p 

            exit
        fi
    fi

    ### vars are like this @{varName}
    ### If snip finds a @{varName}, it asks user for value for varName
    ### and substitutes all the @{varName} with the user inputted value

    vars=()

    for varName in $(echo "$snippet" | awk '{
        while(match($0, /@\{[^}]+\}/)) {
            var = substr($0, RSTART+2, RLENGTH-3)
            print var
            $0 = substr($0, RSTART+RLENGTH)
        }
    }'); do
        found=false
        for item in "${vars[@]}"; do
            if [[ "$item" == "$varName" ]]; then
                found=true
                break
            fi
        done

        if [[ "$found" != true ]]; then
            vars+="$varName"

            userInput=$(gum input --placeholder "Value for $varName")

            snippet="${snippet//\@{$varName\}/$userInput}"
        fi
        
    done

    echo "$snippet" | bat --color=always -p 
}

raw() {
    [ -z "$1" ] && abort "Missing snippet path"

    show "$1" "--raw"
}

run() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"

    # if [ -e "$snippet_path.gpg" ]; then
    #     decrypt "$1"

    #     exit;
    # fi

    # if [ ! -e "$snippet_path" ]; then
    #     abort "\"$snippet_path\" doesn't exists. Exiting ..."
    # fi

    # bat --color=always -p "$snippet_path" -p

    

    cmd=$(show "$@")

    echo "$cmd" | bat --color=always -p 

    echo -e "\nPress CTRL-R to run, or any other key to exit...\n"

    key=""

    read -rsn1 key
    if [[ $key == $'\x12' ]]; then
        eval "$cmd"
    fi
}

## Alias for show
get() {
    show "$1"
}

share() {
    [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"

    if [ -e "$snippet_path.gpg" ]; then
        snippet_path="$snippet_path.gpg"
    fi

    if [ -d "$snippet_path" ]; then
        snippet_path=$(find "$snippet_path" -type f | fzf --delimiter / --with-nth -1 --height=40% --preview "bat --color=always --style=numbers --line-range=:500 {}")
    fi

    if [ ! -f "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists or is a directory. Exiting ..."
    fi

    snippet=""

    if [[ "$snippet_path" == *.gpg ]]; then

        if gum confirm "$1 is encrypted, are you sure to share it unencrypted ?"; then
            snippet=$(decrypt "$1")
        else
            exit
        fi
    else
        snippet=$(cat "$snippet_path")
    fi

    echo "$snippet" | nc termbin.com 9999
}

sync() {
    if [ ! -e "$SNIP_DIR/.git" ]; then
        abort "\"$SNIP_DIR\" is not a git repository, you must init a git repository inside it before you can sync"
    fi

    commitMessage="$1"

    if [ -z "$commitMessage" ]; then
        commitMessage="Updated Snippets $(date "+%Y-%m-%d %H:%M:%S")"
    fi

    cd "$SNIP_DIR"

    git add .
    git commit -m "Updated Snippets"
    git push

    echo "[*] Done";
}

# Add bla=$(echo "" | rofi -dmenu -p "Enter Text > "); echo "${bla}"
runrofi() {
    action="$1"

    if [ -z "$action" ]; then
        action="--copy"
    fi

    theme="$ROFI_USER_THEME"
    snippet_path=""

    if [ "$action" == "-a" ] || [ "$action" == "--add" ]; then
        if [ -z $theme ]; then
            snippet_path=$(find "$SNIPPETS_DIR" -type d | sed -e "s#$SNIPPETS_DIR/##g" | rofi -dmenu -p " snip $action")
        else
            snippet_path=$(find "$SNIPPETS_DIR" -type d | sed -e "s#$SNIPPETS_DIR/##g" | rofi -theme "$theme" -p " snip $action" -dmenu -i)
        fi

        if [ -z "$snippet_path" ]; then
            exit;
        fi

        if [ -d "$SNIPPETS_DIR/$snippet_path" ]; then
            snippet_name=$(rofi -dmenu -theme-str 'listview { enabled: false;}' -p ' Snippet Name >>')
            
            snippet_path="$snippet_path/$snippet_name"
        fi

        add "$snippet_path"

        exit
    fi

    if [ -z $theme ]; then
        snippet_path=$(find "$SNIPPETS_DIR" -type f | sed -e "s#$SNIPPETS_DIR/##g" | rofi -p " snip $action" -dmenu -i)
    else
        snippet_path=$(find "$SNIPPETS_DIR" -type f | sed -e "s#$SNIPPETS_DIR/##g" | rofi -theme "$theme" -p " snip $action" -dmenu -i)
    fi

    if [ -z "$snippet_path" ]; then
        exit;
    fi

    snippet_path="$SNIPPETS_DIR/$snippet_path"

    if [ "$action" == "-e" ] || [ "$action" == "--edit" ]; then
        "$EDITOR" "$snippet_path"
    elif [ "$action" == "-c" ] || [ "$action" == "--copy" ]; then
        cat "$snippet_path" | pbcopy

        notify-send "SNIP SNIPPETS MANAGER" "Copied $(basename "$snippet_path") To Clipboard"
    fi
}

config() {
    var="$1"

    if [ -z "$1" ]; then
        echo -e "Usage:\n"

        echo "$(basename "$0") config home -> print snip home path"
        echo "$(basename "$0") config snippets -> print snippets path"
        echo "$(basename "$0") config dotenv -> print config file (.env)"
        echo "$(basename "$0") config edit -> edit config file (.env)"
        echo "$(basename "$0") config editor -> print current EDITOR"
        exit
    fi

    if [ "$1" == "home" ]; then
        echo "$SNIP_DIR"
    elif [ "$1" == "snippets" ]; then
        echo "$SNIPPETS_DIR"
    elif [ "$1" == "dotenv" ]; then
        echo "$SNIP_CONFIG"
    elif [ "$1" == "editor" ]; then
        which "$EDITOR"
    elif [ "$1" == "edit" ]; then
        "$EDITOR" "$SNIP_CONFIG"
    fi
}

help() {
    echo -e "\nUsage:\n"
    echo -e "\t$(basename "$0") <cmd> [<args>]"

    COUNT=${#cmds[@]}
    for ((i=0; i<$COUNT; i++));do
            echo -e "\t\t${cmds[i]}|${alss[i]}: ${msgs[i]}"
    done

    echo
}

gpg_id() {
    if [ -z "$1" ]; then
        if [ ! -f "$SNIP_GPG_ID_FILEPATH" ]; then
            abort "Missing Param: GPG ID"
        else
            echo -e "$SNIP_DIR/.gpgid:\n" && cat "$SNIP_DIR/.gpgid"
        fi

        exit
    fi

    gpgId="$1"
    shift

    echo "$gpgId" > "$SNIP_DIR/.gpgid"
}

cmd="$1"

if [ -z "$1" ]; then

    cmd="help"

fi

cmd_found=false

# Take command and run script
for ((i=0; i<$COUNT; i++)); do
        if [ "$cmd" = "${cmds[i]}" -o "$cmd" = "${alss[i]}" ]; then

                cmd_found=true

                shift

                ${cmds[i]} "$@"
                break
        
        fi
done

if [ $cmd_found == false ]; then

    if [ -z "$1" ]; then

        help
        exit

    fi

fi 
