#!/bin/bash

original_args=("$@")
args=("$@")

temp_dir="../TempFiles"
dangerous_files=("dinput8.dll")

zenity_title="ELDEN RING - Steam Launch Mode"

vanilla_version="Vanilla"
seamless_version="SeamlessCoop"
modengine2_version="ModEngine2"
version_choice=""

final_text=""

append_to_final_text() {
    final_text+="- "
    final_text+="$@"
    final_text+="\n"
    notify-send $final_text
}

create_temp_dir() {
    if [ -d $temp_dir ]; then
        return
    fi

    mkdir $temp_dir
}

move_file_or_dir_to_temp() {
    curr_path="./$1"
    if ! [ -e $curr_path ]; then
        return
    fi

    new_path="$temp_dir/$1"
    mv $curr_path $new_path
}

restore_file_or_dir_in_temp() {
    curr_path="$temp_dir/$1"
    if ! [ -e $curr_path ]; then
        return
    fi

    new_path="./$1"
    mv $curr_path $new_path
}

move_out_dangerous_files() {
    for file in ${dangerous_files[@]}; do
        move_file_or_dir_to_temp $file
    done
}

restore_dangerous_files() {
    for file in ${dangerous_files[@]}; do
        restore_file_or_dir_in_temp $file
    done
}

replace_start_protected_game_exec_with() {
    args=()
    for arg in "${original_args[@]}"; do
        case "$arg" in
        *"/start_protected_game.exe")
        args+=("${arg%/*.exe}/$1.exe") ;;
        *) args+=("$arg") ;;
        esac
    done
}

switch_to_vanilla() {
    move_out_dangerous_files
}

switch_to_modengine2() {
    if ! [ -e "./mods/modengine2.dll" ] || ! [ -e "./mods/lua.dll" ]; then
        zenity --title=$zenity_title --error \
            --text="Missing Proton Compatible Cloudef/ModEngine2.\nCheck \nhttps://github.com/Cloudef/ModEngine2/releases\nfor help, exiting\nLog:\n$final_text"
        exit
    fi

    restore_dangerous_files
    replace_start_protected_game_exec_with "eldenring"
    export WINEDLLOVERRIDES="dinput8.dll=n,b"
}

switch_to_seamless() {
    if ! [ -e "./launch_elden_ring_seamlesscoop.exe" ]; then
        zenity --error --title=$zenity_title --text="Missing Seamless Coop executable (launch_elden_ring_seamlesscoop.exe), exiting\nLog:\n$final_text"
        exit
    fi
    
    move_out_dangerous_files
    replace_start_protected_game_exec_with "launch_elden_ring_seamlesscoop"
}

handle_version_choice() {
    case $version_choice in
        $seamless_version)
            append_to_final_text "Seamless Coop Chosen"
            switch_to_seamless
            ;;
        $modengine2_version)
            append_to_final_text "Mod Engine 2 Chosen"
            switch_to_modengine2
            ;;
        $vanilla_version)
            append_to_final_text "Defaulting to Vanilla"
            switch_to_vanilla
            ;;
        *)
            exit
            ;;
    esac
}

# Zenity <3.12.1 has a radiolist bug; Steam's zenity is 3.4.0; Assume system zenity is newer
zenity_exec="$(command -pv zenity)"

if [ -n $zenity_exec ]; then
    version_choice=$($zenity_exec --title="$zenity_title" \
        --list --radiolist --text="Select the game version to launch" \
        --column=" " --column="Game Version" \
        0 "$vanilla_version" \
        1 "$seamless_version" \
        2 "$modengine2_version")
fi

handle_version_choice

#zenity --info --title=$zenity_title --text="$final_text"

if command -v gamemoderun; then
    exec gamemoderun  "${args[@]}"
else
    exec ${args[@]}
fi
