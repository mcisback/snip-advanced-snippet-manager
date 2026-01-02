#!/bin/bash
# Snippet Manager in Bash

# NOTE: notification for Mac:
##  osascript -e 'display notification "Build finished" with title "CI" subtitle "Success"'
## or terminal-notifier
# TODO: add trash


case "$(uname -s)" in
    Darwin)
        # macOS code here
        ;;
    Linux)
        # Linux code here
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac


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
"doctor"
"otp"
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
"doc"
"otp"
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
"Check if all requirements are met"
"Store OTP secrets in otp folder. If otp exists, show the code else it create a new one"
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

doctor() {
    ALL_OK=false
    if [ -n "$(which gum)" ]; then
        ALL_OK=true
        echo "✅ gum is installed"
    else
        ALL_OK=false
        echo "⚠️ gum is not installed (required). Install it from here: https://github.com/charmbracelet/gum"
    fi

    echo

    if [ -n "$(which fzf)" ]; then
        ALL_OK=true
        echo "✅ fzf is installed"
    else
        ALL_OK=false
        echo "⚠️ fzf is not installed (required). Install it from here: https://github.com/junegunn/fzf"
    fi

    echo

    if [ -n "$(which bat)" ]; then
        ALL_OK=true
        echo "✅ bat is installed"
    else
        ALL_OK=false
        echo "⚠️ bat is not installed (required). Install it from here: https://github.com/sharkdp/bat"
    fi

    echo

    if [ -n "$(which gpg)" ]; then
        ALL_OK=true
        echo "✅ gpg is installed"
    else
        ALL_OK=false
        echo "⚠️ gpg is not installed (required). Install it before using snip."
    fi

    echo
    echo

    if [ "$ALL_OK" = true ]; then
        echo "✅ All required tools are installed"
    else
        echo "⚠️ Some required tools are missing. Please install them before using snip."
    fi
}

add() {
    s_path="$1"

    if [ -z "$1" ]; then
        s_path=$(gum input --placeholder "Snippet path")
    fi

    snippet_path="$SNIPPETS_DIR/$s_path"
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


    action=$(gum choose "inline" "open $EDITOR")

    case "$action" in
        "inline")
           snippet=$(gum write --placeholder "Snippet content")

           echo "$snippet" > "$snippet_path"
           ;;
        "open $EDITOR")
           edit "$s_path"
           ;;
        *)
            edit "$s_path"
            ;;
    esac
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

    gpg --yes -e -r "$gpgId" $filename

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
    if [ -z "$1" ]; then
        snippet_path=$(find "$SNIPPETS_DIR" -type f | sed -e "s#$SNIPPETS_DIR/##g" | fzf --height=40% --preview "bat --color=always --style=numbers --line-range=:500 '$SNIPPETS_DIR/{}'")

        if [ -z "$snippet_path" ]; then
            exit
        fi

        snippet_path="$SNIPPETS_DIR/$snippet_path"
    else
        snippet_path="$SNIPPETS_DIR/$1"
    fi

    if [ -f "$snippet_path.gpg" ]; then
        gpgId="$(cat $SNIP_GPG_ID_FILEPATH | tr -d '\n' | tr -d ' ')"
        snippet=$(gpg -q -d -u "$gpgId" "$snippet_path.gpg")

        tmp=$(mktemp)
        echo "$snippet" > "$tmp"

        if [[ "$(uname -s)" == "Darwin" ]]; then
            last_mod=$(stat -f %m "$tmp")
        elif [[ "$(uname -s)" == "Linux" ]]; then
            last_mod=$(stat -c %Y "$tmp")
        fi

        $EDITOR "$tmp" &

        echo "Hit Ctrl-C to exit encrypted edit mode ..."

        while true; do
            if [[ "$(uname -s)" == "Darwin" ]]; then
                current_mod=$(stat -f %m "$tmp")
            elif [[ "$(uname -s)" == "Linux" ]]; then
                current_mod=$(stat -c %Y "$tmp")
            fi

            if [ "$current_mod" != "$last_mod" ]; then
                echo "File saved! Running action..."

                rm -f "$snippet_path.gpg"

                cat "$tmp" > "$snippet_path"
                encrypt "$1"

                last_mod=$current_mod
            fi
            sleep 1
        done

        exit
    fi

    if [ ! -f "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists or is a directory. Exiting ..."
    fi

    $EDITOR "$snippet_path"
}

del() {
    if [ -z "$1" ]; then
        snippet_path=$(find "$SNIPPETS_DIR" -mindepth 1 | sed -e "s#$SNIPPETS_DIR/##g" | fzf --height=40% --preview "bat --color=always --style=numbers --line-range=:500 '$SNIPPETS_DIR/{}'")

        if [ -z "$snippet_path" ]; then
            exit
        fi

        snippet_path="$SNIPPETS_DIR/$snippet_path"
    else
        snippet_path="$SNIPPETS_DIR/$1"
    fi

    if [ ! -e "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists. Exiting ..."
    fi

    if [ -d "$snippet_path" ]; then
        echo "⚠️ \"$snippet_path\" is a directory containing multiple snippets..."

        if gum confirm "Confirm deletion ?" --default="no"; then
            rm -rdf "$snippet_path"
        else
            echo "Abort"
        fi

        exit
    fi

    rm "$snippet_path"

    echo "✅ Deleted \"$snippet_path\""
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

    if [ ! -d "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists. Exiting ..."
    fi

    action="$1"

    snippet_path=$(find "$snippet_path" -type f | sed -e "s#$SNIPPETS_DIR/##g" | fzf --height=40% --preview "bat --color=always --style=numbers --line-range=:500 '$SNIPPETS_DIR/{}'")

    if [ -z "$snippet_path" ]; then
       exit
    fi

    if [ -z "$action" ]; then
        action=$(gum choose "show" "edit" "delete")
    fi

    if  [ "$action" == "edit" ]; then
        snippet_path=$(echo "$snippet_path" | sed 's#\.gpg$##')
        edit "$snippet_path"
    elif [ "$action" == "show" ]; then
        show "$snippet_path"
    elif [ "$action" == "delete" ]; then
        del "$snippet_path"
    fi
}

show() {
    # [ -z "$1" ] && abort "Missing snippet path"

    snippet_path="$SNIPPETS_DIR/$1"

    if [ -e "$snippet_path.gpg" ]; then
        snippet_path="$snippet_path.gpg"
    fi

    if [ -d "$snippet_path" ]; then
        snippet_path="$SNIPPETS_DIR/$(find "$snippet_path" -type f | sed -e "s#$SNIPPETS_DIR/##g" | fzf --height=40% --preview "bat --color=always --style=numbers --line-range=:500 "$SNIPPETS_DIR/{}"")"

        # echo "Snippet Path: $snippet_path"
        # exit

        if [ -z "$snippet_path" ]; then
            exit
        fi

        # echo "Snippet Path: $snippet_path"

        # if [ -f "$snippet_path.gpg" ]; then
        #     echo "HERE"
        #     snippet_path="$snippet_path.gpg"
        # fi
    fi

    if [ ! -f "$snippet_path" ]; then
        abort "\"$snippet_path\" doesn't exists or is a directory. Exiting ..."
    fi

    snippet=""

    if [[ "$snippet_path" == *.gpg ]]; then
        gpgId="$(cat $SNIP_GPG_ID_FILEPATH | tr -d '\n' | tr -d ' ')"
        snippet=$(gpg -q -d -u "$gpgId" "$snippet_path")
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

        if gum confirm "$1 is encrypted, are you sure to share it unencrypted ?" --default="no"; then
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
    if [ -z "$(which rofi)" ]; then
        echo "⚠️ rofi is not installed, install it before using this command"
        exit 1
    fi

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

otp() {
    action="show"

    if [ "$1" == "edit" ]; then
        action="edit"
        shift
    elif [ "$1" == "del" ]; then
        action="del"
        shift
    elif [ "$1" == "show" ]; then
        shift
    fi

    OTP_DIR="$SNIPPETS_DIR/otp"
    s_path="$1"

    if [ ! -d "$OTP_DIR" ]; then
        mkdir -p "$OTP_DIR"
    fi

    if [ -z "$s_path" ]; then
        snippet_path=$(find "$OTP_DIR" -type f | sed -e "s#$OTP_DIR/##g" | fzf --height=40% --preview "bat --color=always --style=numbers --line-range=:500 '$OTP_DIR/{}'")

        if [ -z "$snippet_path" ]; then
            exit
        fi

        snippet_path="$OTP_DIR/$snippet_path"
        snippet_path=$(echo "$snippet_path" | sed 's#\.gpg$##')
    else
        snippet_path="$OTP_DIR/$s_path"
    fi

    if [ -f "$snippet_path.gpg" ]; then
        gpgId="$(cat $SNIP_GPG_ID_FILEPATH | tr -d '\n' | tr -d ' ')"
        otpSecret=$(gpg -q -d -u "$gpgId" "$snippet_path.gpg")

        if [ "$action" == "show" ]; then
            otp=$(oathtool --totp --base32 "$otpSecret")
            echo "$otp"
        elif [ "$action" == "edit" ]; then
            otpSecret=$(gum input --placeholder "Edit Encrypted OTP Secret" --value="$otpSecret")

            echo "$otpSecret" > "$snippet_path"

            snippet_path=$(echo "$snippet_path" | sed "s#^$SNIPPETS_DIR/##")

            encrypt "$snippet_path"
        elif [ "$action" == "del" ]; then
            rm -f "$snippet_path.gpg"

            echo "✅ Deleted $snippet_path.gpg"
        fi

        exit
    fi

    if [ ! -f "$snippet_path" ]; then
        otpSecret=$(gum input --placeholder "Enter New OTP Secret")

        if [ -z "$otpSecret" ]; then
            echo "⚠️ OTP Secret cannot be empty"
            exit
        fi

        mkdir -p "$(dirname "$snippet_path")"

        echo "$otpSecret" > "$snippet_path"

        if gum confirm "Do you want to encrypt the otp?" --default="no"; then
            encrypt "otp/$s_path"
        fi

        exit
    fi

    otpSecret=$(cat "$snippet_path")
    if [ "$action" == "show" ]; then
        otp=$(oathtool --totp --base32 "$otpSecret")
        echo "$otp"
    elif [ "$action" == "edit" ]; then
        otpSecret=$(gum input --placeholder "Edit OTP Secret" --value="$otpSecret")

        echo "$otpSecret" > "$snippet_path"
    elif [ "$action" == "del" ]; then
        rm -f "$snippet_path"

        echo "✅ Deleted $snippet_path"
    fi
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
