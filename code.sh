#!/bin/bash


# File to store student records
DATA_FILE="student_records.txt"
# Teacher credentials set by default
TEACHER_USERNAME="teacher"
TEACHER_PASSWORD="fast123"

# Function to calculate grade based on obtained marks and total marks
calculate_grade() {
    obtained=$1
    total=$2
    percentage=$(( (obtained * 100) / total ))

    if [ $percentage -ge 90 ]; then
        echo "A"
    elif [ $percentage -ge 80 ]; then
        echo "B"
    elif [ $percentage -ge 70 ]; then
        echo "C"
    elif [ $percentage -ge 60 ]; then
        echo "D"
    else
        echo "F"
    fi
}

# Function to add a new teacher
add_new_teacher() {
    echo "Enter new teacher username: "
    read username

    # Check if username already exists
    if grep -q "^$username," teacher_records.txt; then
        echo "Error: Username '$username' already exists! Please choose a different username."
        return
    fi

    echo "Enter new teacher password: "
    read -s password   # -s hides input while typing
    echo   # line break

    echo "$username,$password" >> teacher_records.txt
    touch "${username}.txt"
    echo "New teacher added successfully! File '${username}.txt' created."
}

# Function to save student details to file
save_student() {
    local data_file=$1
    local roll=$2
    local password=$3
    local name=$4
    local cgpa=$5
    local subjects=$6  # subjects is comma-prefixed string like: ,subject1(...),subject2(...)
    echo "$roll,$password,$name,$cgpa,$subjects" >> $data_file
}

# Function to view student record
view_student_record() {
    local data_file=$1
    echo "Enter Roll Number: "
    read roll
    
    
    # Search for student record
    record=$(grep "^$roll," "$data_file")
    if [ -z "$record" ]; then
        echo "No record found."
    else
        # Extract fields, skipping the password field
        roll=$(echo "$record" | cut -d',' -f1)
        name=$(echo "$record" | cut -d',' -f3)
        cgpa=$(echo "$record" | cut -d',' -f4)

        echo "Roll Number: $roll"
        echo "Name: $name"
        echo "CGPA: $cgpa"
        echo "Subjects & Marks:"

        # Extract the part of the record after CGPA (all subjects)
        subjects_part=$(echo "$record" | cut -d',' -f5-)

        # Use grep -oP to extract each subject entry (like r(12,30,F))
        echo "$subjects_part" | grep -oP '[^,]+?\([^)]+\)' | while read -r subject_entry; do
            subject_name=$(echo "$subject_entry" | cut -d'(' -f1)
            inside_brackets=$(echo "$subject_entry" | grep -oP '\(.*\)' | tr -d '()')
            obtained_marks=$(echo "$inside_brackets" | cut -d',' -f1)
            total_marks=$(echo "$inside_brackets" | cut -d',' -f2)
            grade=$(echo "$inside_brackets" | cut -d',' -f3)

            if [ "$obtained_marks" == "-" ] || [ -z "$obtained_marks" ]; then
                echo "  $subject_name - Marks not assigned yet."
            else
                echo "  $subject_name: $obtained_marks / $total_marks   Grade: $grade"
            fi
        done
    fi
}

# Function to add a new student
add_student() {
    local data_file=$1
    echo "Enter Roll Number: "
    read roll
    echo "Enter Name: "
    read name
  

    subjects=()
    total_cgpa_points=0
    subject_count=0

# While loop to add subjects
    while true; do
        echo "Do you want to add a subject? (y/n)"
        read choice
        if [ "$choice" = "y" ]; then
            echo "Enter Subject Name: "
            read subject_name
            echo "Enter obtained marks (or '-' if not assigning now): "
            read obtained_marks
            echo "Enter total marks (or '-' if not assigning now): "
            read total_marks
            grade="-"

            # Calculate grade if marks are valid
            if [[ "$obtained_marks" =~ ^[0-9]+$ && "$total_marks" =~ ^[0-9]+$ ]]; then
                grade=$(calculate_grade "$obtained_marks" "$total_marks")
                grade_point=$(grade_to_cgpa "$grade")
                total_cgpa_points=$(echo "$total_cgpa_points + $grade_point" | bc)
                subject_count=$((subject_count + 1))
            fi

            subjects+=("${subject_name}(${obtained_marks},${total_marks},${grade})")
        else
            break
        fi
    done

     # Calculate CGPA if subjects were added
    if [ "$subject_count" -gt 0 ]; then
        cgpa=$(echo "scale=2; $total_cgpa_points / $subject_count" | bc -l)
    else
        cgpa="-"
    fi
    # Save student record
    echo "$roll,"-",$name,$cgpa,${subjects[*]}" >> "$data_file"
    echo "Student added successfully."
}


# CGPA based on grade
grade_to_cgpa() {
    grade=$1
    case $grade in
        A) echo "4.0";;
        B) echo "3.0";;
        C) echo "2.0";;
        D) echo "1.0";;
        F) echo "0.0";;
        *) echo "0.0";;
    esac
}


# Function to load student data file, creating it if necessary
load_students() {
    local data_file=$1
    if [ ! -f $data_file ]; then
        echo "Not present such file yet but we created a new one for you"
        touch $data_file

    fi
}

# Function to delete a student record
delete_student() {
    local data_file=$1
    echo "Enter Roll Number to delete: "
    read roll
    grep -v "^$roll," $data_file > temp && mv temp $data_file
    echo "Student record deleted if existed."
}

# Function to assign marks to students
assign_marks() {
    local data_file=$1
    echo "Enter Roll Number to assign marks: "
    read roll
    
    # Search for student record using roll number
    student=$(grep "^$roll," "$data_file")

    if [ -z "$student" ]; then
        echo "Student not found!"
        return
    fi

    # Split student data into an array using ',' as delimiter
    IFS=',' read -ra fields <<< "$student"
    total_cgpa_points=0
    subject_count=0

    for (( i=4; i<${#fields[@]}; i++ )); do
        subject_name=$(echo "${fields[i]}" | cut -d'(' -f1)
        inside_brackets=$(echo "${fields[i]}" | grep -oP '\(.*\)' | tr -d '()')
        obtained_marks=$(echo "$inside_brackets" | cut -d',' -f1)
        total_marks=$(echo "$inside_brackets" | cut -d',' -f2)
        grade=$(echo "$inside_brackets" | cut -d',' -f3)

        # Check if marks are not assigned (i.e., "-" present in obtained_marks or total_marks)
        if [ "$obtained_marks" == "-" ] || [ "$total_marks" == "-" ]; then
            echo "Subject: $subject_name"
            
            # Prompt for obtained marks and total marks if not already entered
            if [ "$obtained_marks" == "-" ]; then
                echo "Enter obtained marks for $subject_name: "
                read new_obtained
                obtained_marks="$new_obtained"
            fi

            if [ "$total_marks" == "-" ]; then
                echo "Enter total marks for $subject_name: "
                read new_total
                total_marks="$new_total"
            fi

            # Validate the obtained and total marks
            if [[ "$obtained_marks" =~ ^[0-9]+$ && "$total_marks" =~ ^[0-9]+$ ]]; then
                grade=$(calculate_grade "$obtained_marks" "$total_marks")
                grade_point=$(grade_to_cgpa "$grade")
                total_cgpa_points=$(echo "$total_cgpa_points + $grade_point" | bc)
                subject_count=$((subject_count + 1))
            else
                echo "Invalid marks entered, skipping subject."
                continue
            fi
        fi

        # Update the fields with new obtained marks, total marks, and grade
        fields[i]="${subject_name}(${obtained_marks},${total_marks},${grade})"
    done

    # Calculate the new CGPA if subjects were updated
    if [ "$subject_count" -gt 0 ]; then
        cgpa=$(echo "scale=2; $total_cgpa_points / $subject_count" | bc -l)
    else
        cgpa="-"
    fi

    # Update the student record with the new CGPA and subject details
    updated_record="${fields[0]},${fields[1]},${fields[2]},$cgpa"
    for (( i=4; i<${#fields[@]}; i++ )); do
        updated_record+=","${fields[i]}
    done

    # Update the file with the new record
    awk -v roll="$roll" -v new_record="$updated_record" -F',' '
        BEGIN { OFS="," }
        $1 == roll { print new_record; next }
        { print }
    ' "$data_file" > temp && mv temp "$data_file"

    echo "Marks assigned and CGPA updated for student $roll."
}


# Function to add new subjects if needed
add_more_subjects() {
    local data_file=$1
    echo "Enter Roll Number to add subjects: "
    read roll
    student=$(grep "^$roll," "$data_file")

    if [ -z "$student" ]; then
        echo "Student not found!"
        return
    fi

    IFS=',' read -ra fields <<< "$student"
    total_cgpa_points=0
    subject_count=0

    for (( i=4; i<${#fields[@]}; i++ )); do
        inside_brackets=$(echo "${fields[i]}" | grep -oP '\(.*\)' | tr -d '()')
        obtained_marks=$(echo "$inside_brackets" | cut -d',' -f1)
        total_marks=$(echo "$inside_brackets" | cut -d',' -f2)
        grade=$(echo "$inside_brackets" | cut -d',' -f3)

        if [[ "$obtained_marks" =~ ^[0-9]+$ && "$total_marks" =~ ^[0-9]+$ ]]; then
            grade_point=$(grade_to_cgpa "$grade")
            total_cgpa_points=$(echo "$total_cgpa_points + $grade_point" | bc -l)
            subject_count=$((subject_count + 1))
        fi
    done

    while true; do
        echo "Do you want to add a new subject for $roll? (y/n)"
        read choice
        if [ "$choice" = "y" ]; then
            echo "Enter Subject Name: "
            read subject_name
            echo "Enter obtained marks (or '-' if not assigning now): "
            read obtained_marks
            echo "Enter total marks (or '-' if not assigning now): "
            read total_marks
            grade="-"

            if [[ "$obtained_marks" =~ ^[0-9]+$ && "$total_marks" =~ ^[0-9]+$ ]]; then
                grade=$(calculate_grade "$obtained_marks" "$total_marks")
                grade_point=$(grade_to_cgpa "$grade")
                total_cgpa_points=$(echo "$total_cgpa_points + $grade_point" | bc)
                subject_count=$((subject_count + 1))
            fi

            fields+=("${subject_name}(${obtained_marks},${total_marks},${grade})")
        else
            break
        fi
    done
    
    # Calculate the new CGPA 
    if [ "$subject_count" -gt 0 ]; then
        cgpa=$(echo "scale=2; $total_cgpa_points / $subject_count" | bc)
    else
        cgpa="-"
    fi

    updated_record="${fields[0]},${fields[1]},${fields[2]},$cgpa"
    for (( i=4; i<${#fields[@]}; i++ )); do
        updated_record+=","${fields[i]} # Append each subject record to the updated record
    done

    # Update the student record in the file
    awk -v roll="$roll" -v new_record="$updated_record" -F',' '
        BEGIN { OFS="," }
        $1 == roll { print new_record; next }
        { print }
    ' "$data_file" > temp && mv temp "$data_file"

    echo "Subjects added and CGPA updated for student $roll."
}

# Function to list students sorted by CGPA
list_students_sorted() {
    local data_file=$1
    echo "1. Ascending order by CGPA  2. Descending order by CGPA"
    read choice
    if [ "$choice" -eq 1 ]; then
        sort -t',' -k4 -n "$data_file" | awk -F',' '{print $1, $3, $4}' | column -t
    else
        sort -t',' -k4 -nr "$data_file" | awk -F',' '{print $1, $3, $4}' | column -t
    fi
}

# Function to list students who passed (CGPA >= 2.0)
list_passed_students() {
    local data_file=$1
    echo "Passed Students (CGPA >= 2.0):"
    awk -F',' '$4 >= 2.0 {print $1, $3, $4}' "$data_file" | column -t
}

# Function to list students who failed (CGPA < 2.0)
list_failed_students() {
    local data_file=$1
    echo "Failed Students (CGPA < 2.0):"
    awk -F',' '$4 < 2.0 {print $1, $3, $4}' "$data_file" | column -t
}

# Function to handle student login
student_login() {
    echo "Enter your Roll Number: "
    read roll

    teachers=$(cut -d',' -f1 teacher_records.txt)

    found=0
    for teacher_username in $teachers; do
        data_file="${teacher_username}.txt"
        if [ -f "$data_file" ]; then
            student_line=$(grep "^$roll," "$data_file")
            if [ ! -z "$student_line" ]; then
                password_field=$(echo "$student_line" | cut -d',' -f2)

                # If no password is set, the student to set one
                if [ "$password_field" = "-" ]; then
                    echo "It looks like you haven't set a password yet. Please set your new password: "
                    read -s newpass
                    if [ -z "$newpass" ]; then
                        echo "Password cannot be empty. Try logging in again."
                        return
                    fi

                    temp_file="temp.txt"
                    awk -F',' -v roll="$roll" -v newpass="$newpass" 'BEGIN{OFS=","} 
                        {if($1 == roll) $2 = newpass; print}' "$data_file" > "$temp_file"
                    mv "$temp_file" "$data_file"
                    echo "Password set successfully! Please login again with your new password."
                    return
                else
                    echo "Enter your Password: "
                    read -s pass
                    student=$(grep "^$roll,$pass," "$data_file")
                    if [ ! -z "$student" ]; then
                        found=1
                        echo "Welcome! You are logged in from $teacher_username's records."

                        while true; do
                            echo ""
                            echo "Student Panel:"
                            echo "1. View Name"
                            echo "2. View Subject Records"
                            echo "3. View CGPA"
                            echo "4. Logout"
                            read ch
                            case $ch in
                                1) 
                                    name=$(echo "$student" | cut -d',' -f3)
                                    echo "Your Name: $name"
                                    ;;
2)
    echo "Your Subjects Details:"
    # Get subject data from 5th column onwards
    subject_data=$(echo "$student" | cut -d',' -f5-)
    
    # Extract all subject records that follow subjectName(obtained,total,grade) pattern
    subjects=$(echo "$subject_data" | grep -oP '[a-zA-Z0-9]+?\([0-9]+,[0-9]+,[A-Z]\)')

    # Loop through all extracted subjects and print
    while IFS= read -r subject_entry; do
        subject_name=$(echo "$subject_entry" | cut -d'(' -f1)
        inside_brackets=$(echo "$subject_entry" | grep -oP '\(.*\)' | tr -d '()')
        obtained_marks=$(echo "$inside_brackets" | cut -d',' -f1)
        total_marks=$(echo "$inside_brackets" | cut -d',' -f2)
        grade=$(echo "$inside_brackets" | cut -d',' -f3)

        echo "Subject: $subject_name, Obtained Marks: $obtained_marks, Total Marks: $total_marks, Grade: $grade"
    done <<< "$subjects"
    ;;


                                3)
                                    cgpa=$(echo "$student" | cut -d',' -f4)
                                    echo "Your CGPA: $cgpa"
                                    ;;
                                4) 
                                    echo "Logging out..."
                                    break
                                    ;;
                                *) echo "Invalid choice";;
                            esac
                        done
                        break
                    fi
                fi
            fi
        fi
    done

    if [ $found -eq 0 ]; then
        echo "Student record not found or incorrect credentials!"
    fi
}

# Function to handle teacher login
teacher_login() {
    echo "Enter username: "
    read uname
    echo "Enter password: "
    read -s pass

    # Check teacher credentials by searching for the username and password in the teacher records file
    record=$(grep "^$uname,$pass" teacher_records.txt)
    if [ -z "$record" ]; then
        echo "Invalid credentials!"
        return
    fi
    
    # If credentials are valid, assign the teacher's data file and load student records
    data_file="${uname}.txt"
    load_students $data_file
    echo "Login Successful!"
    
    while true; do
        echo ""
        echo "Teacher Panel for $uname:"
        echo "1. Add Student"
        echo "2. Delete Student"
        echo "3. Assign Marks"
        echo "4. List Passed Students"
        echo "5. List Failed Students"
        echo "6. View Student Record"
        echo "7. List Students (Sort by CGPA)"
        echo "8. Add More Subjects to a Student Record"

        echo "9. Logout"
        read ch
        case $ch in
            1) add_student $data_file;;
            2) delete_student $data_file;;
            3) assign_marks $data_file;;
            4) list_passed_students $data_file;;
            5) list_failed_students $data_file;;
            6) view_student_record $data_file;;
            7) list_students_sorted $data_file;;
            8) add_more_subjects "$data_file" ;;

            9) break;;
            *) echo "Invalid choice";;
        esac
    done
}


main_menu() {
    while true; do
        echo ""
        echo "===== Student Management System ====="
        echo "1. Teacher Login"
        echo "2. Student Login"
        echo "3. Add New Teacher"
        echo "4. Exit"
        read choice
        case $choice in
            1) teacher_login ;;
            2) student_login ;;
            3) add_new_teacher ;;
            4) echo "Exiting..."; break ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}

main_menu
