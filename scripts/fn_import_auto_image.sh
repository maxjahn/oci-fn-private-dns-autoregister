#!/usr/bin/env bash

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}


#######


regions=(`oci iam region-subscription list --query 'data[]."region-name"' --output json | jq -r '.[]'`)

echo "Select from your subscribed regions:"
echo

select_option "${regions[@]}"
choice=$?

region=${regions[$choice]}

arr=(`oci iam user list --query "data[].[name, id]" --output json  | jq -r '.[] | @tsv'`)

count=${#arr[*]}
limit=$((count - 1))
k=()
v=()
for i in `seq 0 2 ${limit}`;
do
  k+=(${arr[$i]})
  v+=(${arr[$((i+1))]})
done

echo "Select user to generate auth-token for:"
echo

select_option "${k[@]}"
choice=$?

user_name=${k[$choice]}
user_ocid=${v[$choice]}

#token=`oci iam auth-token create --description fn-access --user-id ${user_ocid} --query "data.token" | tr -d \"`
echo "token generated: ${token}"

ns=`oci os ns get --query "data" | tr -d \"`

echo "Docker login with auth-token:"
echo $token | docker login ${region}.ocir.io -u ${ns}/${user_name} --password-stdin

docker pull maxjahn/event-dns-autoregister
docker tag maxjahn/event-dns-autoregister:latest ${region}.ocir.io/${ns}/fn-automation/event-dns-autoregister:latest
docker push ${region}.ocir.io/${ns}/fn-automation/event-dns-autoregister:latest



