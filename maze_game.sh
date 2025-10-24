#!/bin/bash

# ASCII迷宫游戏
# 使用 WASD 或方向键控制，到达出口即可获胜

# 迷宫地图 (# = 墙, . = 路, P = 玩家, E = 出口, * = 宝藏)
declare -a maze=(
    "#####################"
    "#P..................#"
    "#.###.#########.###.#"
    "#.#.#.#.......#.#.#.#"
    "#.#.#.#.#####.#.#.#.#"
    "#...#...#.*.#...#...#"
    "#####.###.#.#####.###"
    "#.....#.#.#.......#.#"
    "#.#####.#.#######.#.#"
    "#.#.....#.......#.#.#"
    "#.#.###########.#.#.#"
    "#.#.#...*.......#...#"
    "#.#.#.#############.#"
    "#.#...#.............#"
    "#.#####.#############"
    "#...................E"
    "#####################"
)

player_x=1
player_y=1
score=0
moves=0

original_stty=$(stty -g)

cleanup() {
    stty "$original_stty"
    tput cnorm
    clear
    echo "游戏结束！"
    echo "总移动步数: $moves"
    echo "收集宝藏: $score"
    exit 0
}

trap cleanup EXIT INT TERM

init_terminal() {
    clear
    tput civis
    stty -echo -icanon time 0 min 0
}

draw_maze() {
    tput cup 0 0
    local y=0
    for row in "${maze[@]}"; do
        if [ $y -eq $player_y ]; then
            local before="${row:0:$player_x}"
            local after="${row:$((player_x + 1))}"
            echo "${before}P${after}"
        else
            echo "$row"
        fi
        ((y++))
    done
    echo ""
    echo "控制: W/↑=上, S/↓=下, A/←=左, D/→=右, Q=退出"
    echo "目标: 到达出口 (E)"
    echo "移动步数: $moves  |  宝藏: $score"
}

can_move() {
    local x=$1
    local y=$2
    local row="${maze[$y]}"
    local cell="${row:$x:1}"
    
    if [ "$cell" = "." ] || [ "$cell" = "E" ] || [ "$cell" = "*" ]; then
        return 0
    fi
    return 1
}

move_player() {
    local new_x=$player_x
    local new_y=$player_y
    
    case $1 in
        w|W|A) ((new_y--)) ;;
        s|S|B) ((new_y++)) ;;
        a|A|D) ((new_x--)) ;;
        d|D|C) ((new_x++)) ;;
        q|Q) cleanup ;;
        *) return ;;
    esac
    
    if can_move $new_x $new_y; then
        local row="${maze[$new_y]}"
        local cell="${row:$new_x:1}"
        
        if [ "$cell" = "E" ]; then
            draw_maze
            tput cup $((${#maze[@]} + 4)) 0
            echo ""
            echo "🎉 恭喜！你找到了出口！"
            echo "总移动步数: $moves"
            echo "收集宝藏: $score"
            sleep 3
            cleanup
        fi
        
        if [ "$cell" = "*" ]; then
            ((score++))
            local new_row="${row:0:$new_x}.${row:$((new_x + 1))}"
            maze[$new_y]="$new_row"
        fi
        
        local old_row="${maze[$player_y]}"
        maze[$player_y]="${old_row:0:$player_x}.${old_row:$((player_x + 1))}"
        
        player_x=$new_x
        player_y=$new_y
        ((moves++))
    fi
}

read_key() {
    local key
    read -rsn1 key
    
    if [ "$key" = $'\x1b' ]; then
        read -rsn2 key
        case "$key" in
            '[A') move_player w ;;
            '[B') move_player s ;;
            '[C') move_player d ;;
            '[D') move_player a ;;
        esac
    else
        move_player "$key"
    fi
}

main() {
    init_terminal
    
    while true; do
        draw_maze
        read_key
    done
}

main
