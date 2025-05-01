🧑‍💻 Student Management System – Operating Systems Mini Project
This Shell Script-based project simulates a Student Management System for educational institutions, built as part of an Operating Systems lab. It uses bash scripting to handle user authentication, data management, and academic record tracking.
🔑 Key Features:
Teacher Login: Authenticated access to manage student records.
Student Login: Allows students to set a password and view their records securely.
Add New Teacher: Enables the registration of new teachers.
Student Record Management:
Add/Delete student entries
Assign marks and calculate grades
Compute and update CGPA
Add additional subjects post-enrollment
Sorting and Filtering:
List students sorted by CGPA (asc/desc)
View passed (CGPA ≥ 2.0) and failed students
Data Storage:
Individual files per teacher (e.g., ahmad.txt)
Central teacher_records.txt for authentication

### Teacher Module:
- Secure login with username/password
- Add/Delete student records
- Assign marks and auto-calculate **grades and CGPA**
- Add subjects after initial enrollment
- View individual student records
- View passed and failed students
- List students sorted by CGPA (asc/desc)

### Student Module:
- Login with roll number and password setup
- View personal details and CGPA
- View subject-wise grades and marks

### Admin Tools:
- Register new teachers
- Each teacher has their own `.txt` file for student records
- Credentials stored securely in `teacher_records.txt`

📁 Technologies Used:
Bash Shell Scripting
File handling (CRUD operations on .txt files)
Linux command-line utilities (grep, awk, cut, sort, bc)
