#! /usr/bin/env bash

config_file="$HOME/.config/alacritty/alacritty.toml"
regular_fonts=$(fc-list : family style | awk -F, '/Regular/ {print $1}' | cut -d: -f1 | sed -E 's/[^ 0-9a-zA-Z]+$//; s/[^ 0-9a-zA-Z]+/\\&/g' | sort | uniq)
# echo "$regular_fonts" && exit;

initial_font=$(cat "$config_file" | grep -A1 "font.normal" | grep -Po "family[^=]*=[^\"]\"*\K[^\"]*")

main() {
    sed -i "s/\"$1\"/\"$2\"/g" "$config_file"
}

stdout() {
    printf "\e[034m$1\e[0m"
}

current_font="$initial_font"
while IFS= read -r next_font; do
    clear
    printf "\e[031m> %s\e[0m\n\n" "$next_font"

    # echo EXECUTE \`sed -i \"s/\\\"$current_font\\\"/\\\"$next_font\\\"/g\" "$config_file"\`? # debug
    # echo "    AKA change \"$current_font\" to \"$next_font\"?" # debug

    choice=
    ACCEPT="a"
    REJECT="r"
    DONE="d"

    while true; do
        stdout "a: accept\tr: reject\td: done\n"
        read -n1 -p ">>> " choice </dev/tty && echo
        case "$choice" in
            $ACCEPT)
                stdout "EXECUTING...\n"
                main "$current_font" "$next_font"
                current_font="$next_font"
                break
                ;;
            $REJECT)
                stdout "ABORTING.\n"
                break
                ;;
            $DONE)
                stdout "DONE.\n"
                break
                ;;
            *)
                echo -e "Invalid command \"$choice\"\n"
                ;;
        esac
    done
    if [[ $choice == "d" ]]; then break; fi
done <<< "$regular_fonts"

if [[ ! "$initial_font" == "$current_font" ]]; then
    stdout "Save changes? [y/N] "
    read save_changes && echo
    save_changes="${save_changes,,}"
    if [[ $save_changes == "n" ]]; then
        stdout "Restoring to \"$initial_font\"...\n"
        main "$current_font" "$initial_font"
    fi
fi
