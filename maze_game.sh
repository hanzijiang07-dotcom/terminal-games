i
#!/bin/bash

# ASCII Maze Game
# Use WASD or arrow keys to move. Reach the exit (E) to win.

# Maze Map (# = wall, . = path, P = player, E = exit, * = treasure, T = task)
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
    "#.#####.#####T#######"
    "#...................E"
    "#####################"
)

player_x=1
player_y=1
score=0
moves=0
task_done=false

original_stty=$(stty -g)

cleanup() {
    stty "$original_stty"
    tput cnorm
    clear
    echo "Game Over!"
    echo "Total moves: $moves"
    echo "Treasures collected: $score"
    exit 0
}

trap cleanup EXIT INT TERM

init_terminal() {
    clear
    tput civis
    stty -echo -icanon time 0 min 0
    mkdir -p tasks
    echo "(empty file, go to the task point to edit)" > tasks/task.txt
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
    echo "Controls: W/↑=Up, S/↓=Down, A/←=Left, D/→=Right, Q=Quit"
    echo "Objective: Reach the exit (E) and complete tasks (*) or (T)"
    echo "Moves: $moves  |  Treasures: $score"
}

can_move() {
    local x=$1
    local y=$2
    local row="${maze[$y]}"
    local cell="${row:$x:1}"

    if [[ "$cell" =~ [\.ET*] ]]; then
        return 0
    fi
    return 1
}

move_player() {
    local new_x=$player_x
    local new_y=$player_y

    case $1 in
        w|W) ((new_y--)) ;;
        s|S) ((new_y++)) ;;
        a|A) ((new_x--)) ;;
        d|D) ((new_x++)) ;;
        q|Q) cleanup ;;
        *) return ;;
    esac

    if can_move $new_x $new_y; then
        local row="${maze[$new_y]}"
        local cell="${row:$new_x:1}"

        # Exit point
        if [ "$cell" = "E" ]; then
            draw_maze
            tput cup $((${#maze[@]} + 4)) 0
            echo ""
            echo "🎉 Congratulations! You reached the exit!"
            echo "Total moves: $moves"
            echo "Treasures collected: $score"
            sleep 3
            cleanup
        fi

        # Treasure
        if [ "$cell" = "*" ]; then
            ((score++))
            local new_row="${row:0:$new_x}.${row:$((new_x + 1))}"
            maze[$new_y]="$new_row"
        fi

        # Task point T
        if [ "$cell" = "T" ] && [ "$task_done" = false ]; then
            draw_maze
            echo -e "\n🧩 Task Triggered!"
            echo "Open 'tasks/task.txt' using vi and write 'Hello Maze'."
            read -p "Press Enter to open vi..." dummy
            vi tasks/task.txt

            if grep -q "Hello Maze" tasks/task.txt; then
                echo "✅ Task Completed! +10 points"
                score=$((score+10))
                task_done=true
            else
                echo "❌ Incorrect content. Try again."
            fi
            sleep 2
        fi

        # Update old player position
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

