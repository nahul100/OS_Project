#!/bin/bash
ROOMS_FILE="rooms.txt"
ALLOC_FILE="allocations.txt"
ADMIN_PASS_FILE="admin_pass.txt"
DATA_DIR="./data"
ROOMS="$DATA_DIR/rooms.txt"
STUDENTS="$DATA_DIR/students.txt"
ALLOCATIONS="$DATA_DIR/allocations.txt"
SESSION_FILE="./.student_session"

touch "$ROOMS_FILE" "$ALLOC_FILE"
if [ ! -f "$ADMIN_PASS_FILE" ]; then
    echo -n "admin123" | sha256sum | awk '{print $1}' > "$ADMIN_PASS_FILE"
fi


ADMIN_PASS_HASH=$(cat "$ADMIN_PASS_FILE")

logged_in=0

function admin_login() {
    echo -n "Enter admin password: "
    read -s pass
    echo
    pass_hash=$(echo -n "$pass" | sha256sum | awk '{print $1}')
    if [ "$pass_hash" == "$ADMIN_PASS_HASH" ]; then
        logged_in=1
        echo "Login successful!"
    else
        echo "Incorrect password."
    fi
}

function admin_logout() {
    logged_in=0
    echo "Logged out."
}

function admin_add_room() {
    echo -n "Enter new room number: "
    read room
    if grep -qx "$room" "$ROOMS_FILE"; then
        echo "Room $room already exists."
    else
        echo "$room" >> "$ROOMS_FILE"
        echo "Room $room added."
    fi
}

function admin_view_rooms() {
    echo "---- All Rooms ----"
    if [ ! -s "$ROOMS_FILE" ]; then
        echo "No rooms available."
    else
        cat "$ROOMS_FILE"
    fi
}

function admin_delete_room() {
    echo -n "Enter room number to delete: "
    read room
    if grep -qx "$room" "$ROOMS_FILE"; then
        grep -vx "$room" "$ROOMS_FILE" > rooms.tmp && mv rooms.tmp "$ROOMS_FILE"
        grep -v "^$room:" "$ALLOC_FILE" > allocations.tmp && mv allocations.tmp "$ALLOC_FILE"
        echo "Room $room and related allocations deleted."
    else
        echo "Room $room not found."
    fi
}

function view_allocations() {
    echo "---- Room Allocations ----"
    if [ ! -s "$ALLOC_FILE" ]; then
        echo "No allocations found."
    else
        while IFS=: read -r room student; do
            echo "Room $room is allocated to $student"
        done < "$ALLOC_FILE"
    fi
}

function admin_menu() {
    echo
    echo "Hostel Admin Portal"
    echo "1) Add Room"
    echo "2) View All Rooms"
    echo "3) Delete Room"
    echo "4) View Allocations"
    echo "5) Logout"
    echo "6) Exit"
    echo -n "Choose an option: "
}
#...Student function Start
function register_student() {
    echo -n "Enter Student ID: "
    read sid
    echo -n "Enter Name: "
    read name

    if grep -q "^$sid," "$STUDENTS"; then
        echo "Student already registered."
    else
        echo "$sid,$name" >> "$STUDENTS"
        echo "Registration successful!"
    fi
}
function student_login() {
    echo -n "Enter Student ID to login: "
    read sid

    if grep -q "^$sid," "$STUDENTS"; then
        echo "$sid" > "$SESSION_FILE"
        echo "Login successful!"
    else
        echo "Student not registered. Please register first."
    fi
}
function view_available_rooms() {
    echo "Available Rooms:"
    grep ",available" "$ROOMS" | cut -d',' -f1
}
function apply_room() {
    sid=$(get_logged_in_user)
    if [ -z "$sid" ]; then
        echo "You must be logged in to apply for a room."
        return
    fi

    grep -q "^$sid," "$ALLOCATIONS" && { echo "Already allocated a room."; return; }

    echo "Available Rooms:"
    grep ",available" "$ROOMS" | cut -d',' -f1
    echo -n "Enter Room Number to apply: "
    read rno

    if grep -q "^$rno,available" "$ROOMS"; then
        echo "$sid,$rno" >> "$ALLOCATIONS"
        sed -i "s/^$rno,available/$rno,occupied/" "$ROOMS"
        echo "Room $rno allocated!"
    else
        echo "Room not available."
    fi
}
function view_my_allocation() {
    sid=$(get_logged_in_user)
    if [ -z "$sid" ]; then
        echo "You must be logged in to view your allocation."
        return
    fi

    alloc=$(grep "^$sid," "$ALLOCATIONS")
    if [ -n "$alloc" ]; then
        room=$(echo "$alloc" | cut -d',' -f2)
        echo "You are allocated Room: $room"
    else
        echo "No allocation found."
    fi
}
function student_logout() {
    rm -f "$SESSION_FILE"
    echo "Logged out successfully!"
}
function student_menu() {
    echo
    echo "Hostel Student Portal"
    echo "1) register_student"
    echo "2) student_login"
    echo "3) view_available_rooms"
    echo "4) apply_room"
    echo "5) view_my_allocation"
    echo "6) student_logout"
    echo "7) exit"
    echo -n "Choose an option: "
}
function main_menu() {
    echo
    echo "Welcome to Hostel Portal"
    echo "1) Admin Login"
    echo "2) Student Login"
    echo "3) Exit"
    echo -n "Choose option: "
}

# Main loop
while true; do
    if [ $logged_in -eq 0 ]; then
        main_menu
        read choice
        case $choice in
            1) admin_login ;;
            2) student_login ;;
            3) echo "Bye!"; exit 0 ;;
            *) echo "Invalid choice." ;;
        esac
    else
        if [ "$user_type" == "admin" ]; then
            admin_menu
            read opt
            case $opt in
                1) admin_add_room ;;
                2) admin_view_rooms ;;
                3) admin_delete_room ;;
                4) admin_view_allocations ;;
                5) admin_logout ;;
                6) exit ;;
                *) echo "Invalid option." ;;
            esac
        elif [ "$user_type" == "student" ]; then
            student_menu
            read opt
            case $opt in
                1) register_student ;;
                2) student_login ;;
                3) view_available_rooms ;;
                4) apply_room ;;
                5) view_my_allocation ;;
                6) student_logout ;;
                7) exit ;;
                *) echo "Invalid option" ;;
            esac
        fi
    fi
done