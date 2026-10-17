-- =====================================================
--  STUDENT MANAGER  -  studentmanager.sql
--  Base de donnees MySQL / MariaDB (sans partie "parents")
--  Import : phpMyAdmin > Importer  (ou)  mysql -u root < studentmanager.sql
-- =====================================================

DROP DATABASE IF EXISTS studentmanager;
CREATE DATABASE studentmanager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE studentmanager;

-- 1) UTILISATEURS (comptes de connexion : admin, teacher, student)
CREATE TABLE users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  full_name   VARCHAR(100) NOT NULL,
  email       VARCHAR(120) NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,
  role        ENUM('admin','teacher','student') NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2) CLASSES
CREATE TABLE classes (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(50) NOT NULL,
  level VARCHAR(50)
) ENGINE=InnoDB;

-- 3) ENSEIGNANTS (profil lie a un compte users)
CREATE TABLE teachers (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL UNIQUE,
  phone      VARCHAR(30),
  speciality VARCHAR(80),
  hire_date  DATE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4) MATIERES
CREATE TABLE subjects (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  code VARCHAR(20) UNIQUE
) ENGINE=InnoDB;

-- 5) CLASSE <-> MATIERE <-> ENSEIGNANT (qui enseigne quoi, dans quelle classe)
CREATE TABLE class_subjects (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  class_id   INT NOT NULL,
  subject_id INT NOT NULL,
  teacher_id INT NOT NULL,
  UNIQUE (class_id, subject_id),
  FOREIGN KEY (class_id)   REFERENCES classes(id)  ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6) DORTOIRS et 7) TRANSPORT
CREATE TABLE dormitories (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(60) NOT NULL,
  capacity INT NOT NULL DEFAULT 20
) ENGINE=InnoDB;

CREATE TABLE transport_routes (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(80) NOT NULL,
  vehicle VARCHAR(60),
  driver  VARCHAR(80),
  fare    DECIMAL(10,2) DEFAULT 0
) ENGINE=InnoDB;

-- 8) ETUDIANTS
CREATE TABLE students (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT NULL UNIQUE,
  admission_no  VARCHAR(20) NOT NULL UNIQUE,
  first_name    VARCHAR(60) NOT NULL,
  last_name     VARCHAR(60) NOT NULL,
  gender        ENUM('Male','Female') NOT NULL,
  birth_date    DATE,
  phone         VARCHAR(30),
  emergency_contact VARCHAR(100),
  class_id      INT NOT NULL,
  dormitory_id  INT NULL,
  transport_id  INT NULL,
  status        ENUM('Active','Pending','Inactive') DEFAULT 'Active',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)      REFERENCES users(id)            ON DELETE SET NULL,
  FOREIGN KEY (class_id)     REFERENCES classes(id),
  FOREIGN KEY (dormitory_id) REFERENCES dormitories(id)      ON DELETE SET NULL,
  FOREIGN KEY (transport_id) REFERENCES transport_routes(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 9) EMPLOI DU TEMPS (class routine)
CREATE TABLE class_routine (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  class_id   INT NOT NULL,
  subject_id INT NOT NULL,
  teacher_id INT NOT NULL,
  day_name   ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') NOT NULL,
  start_time TIME NOT NULL,
  end_time   TIME NOT NULL,
  room       VARCHAR(30),
  FOREIGN KEY (class_id)   REFERENCES classes(id)  ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10) ECHELLE DE NOTES (grades : A, B, C...)
CREATE TABLE grades (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(5) NOT NULL,
  min_mark  DECIMAL(5,2) NOT NULL,
  max_mark  DECIMAL(5,2) NOT NULL,
  comment   VARCHAR(60)
) ENGINE=InnoDB;

-- 11) EXAMENS
CREATE TABLE exams (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(80) NOT NULL,
  class_id   INT NOT NULL,
  exam_date  DATE,
  FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 12) NOTES D'EXAMEN
CREATE TABLE exam_marks (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  exam_id    INT NOT NULL,
  student_id INT NOT NULL,
  subject_id INT NOT NULL,
  mark       DECIMAL(5,2) NOT NULL,
  UNIQUE (exam_id, student_id, subject_id),
  FOREIGN KEY (exam_id)    REFERENCES exams(id)    ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 13) PRESENCES
CREATE TABLE attendance (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  student_id  INT NOT NULL,
  class_id    INT NOT NULL,
  att_date    DATE NOT NULL,
  status      ENUM('Present','Absent','Late') NOT NULL,
  UNIQUE (student_id, att_date),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (class_id)   REFERENCES classes(id)  ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14) SUPPORTS DE COURS
CREATE TABLE study_materials (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(120) NOT NULL,
  file_name   VARCHAR(200),
  class_id    INT NOT NULL,
  subject_id  INT NOT NULL,
  teacher_id  INT NOT NULL,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (class_id)   REFERENCES classes(id)  ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 15) FACTURES et 16) PAIEMENTS (frais de scolarite)
CREATE TABLE invoices (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  student_id  INT NOT NULL,
  title       VARCHAR(100) NOT NULL,
  amount      DECIMAL(10,2) NOT NULL,
  due_date    DATE,
  status      ENUM('Unpaid','Paid') DEFAULT 'Unpaid',
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payments (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id  INT NOT NULL,
  amount      DECIMAL(10,2) NOT NULL,
  method      ENUM('Cash','Card','Online') DEFAULT 'Cash',
  paid_at     DATE,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 17) COMPTABILITE (revenus et depenses de l'ecole)
CREATE TABLE accounting (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  type        ENUM('Income','Expense') NOT NULL,
  category    VARCHAR(60),
  amount      DECIMAL(10,2) NOT NULL,
  description VARCHAR(200),
  entry_date  DATE NOT NULL
) ENGINE=InnoDB;

-- 18) EVENEMENTS
CREATE TABLE events (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(120) NOT NULL,
  description TEXT,
  event_date  DATE NOT NULL,
  location    VARCHAR(80)
) ENGINE=InnoDB;

-- 19) BIBLIOTHEQUE (livres + emprunts)
CREATE TABLE books (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  title    VARCHAR(150) NOT NULL,
  author   VARCHAR(100),
  quantity INT DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE book_issues (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  book_id     INT NOT NULL,
  student_id  INT NOT NULL,
  issue_date  DATE NOT NULL,
  return_date DATE NULL,
  FOREIGN KEY (book_id)    REFERENCES books(id)    ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 20) MESSAGES entre utilisateurs
CREATE TABLE messages (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  sender_id   INT NOT NULL,
  receiver_id INT NOT NULL,
  subject     VARCHAR(120),
  body        TEXT,
  sent_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 21) SMS envoyes (notes envoyees par SMS)
CREATE TABLE sms_log (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  exam_id    INT NULL,
  content    VARCHAR(300),
  sent_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (exam_id)    REFERENCES exams(id)    ON DELETE SET NULL
) ENGINE=InnoDB;

-- 22) PARAMETRES SYSTEME (general, sms, langue)
CREATE TABLE settings (
  setting_key   VARCHAR(50) PRIMARY KEY,
  setting_value VARCHAR(200)
) ENGINE=InnoDB;


-- =====================  DONNEES D'EXEMPLE  =====================

INSERT INTO users (id, full_name, email, password, role) VALUES
  (1, 'Admin Principal', 'admin@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
  (2, 'Karim Bennani', 'teacher1@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher'),
  (3, 'Salma Idrissi', 'teacher2@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher'),
  (4, 'Youssef Alaoui', 'teacher3@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher'),
  (5, 'Nadia Chraibi', 'teacher4@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher'),
  (6, 'Omar Tazi', 'teacher5@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher'),
  (7, 'Leila Fassi', 'teacher6@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher'),
  (8, 'Meryem Haddad', 'student1@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (9, 'Ayoub Rifi', 'student2@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (10, 'Douae Mansouri', 'student3@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (11, 'Kawtar Skalli', 'student4@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (12, 'Ilyas Zaidi', 'student5@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (13, 'Zineb Naciri', 'student6@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (14, 'Mehdi Bouzid', 'student7@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (15, 'Ahmed Kettani', 'student8@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (16, 'Saad Lahlou', 'student9@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (17, 'Zakaria Berrada', 'student10@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (18, 'Lina Chakir', 'student11@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (19, 'Aya Ouazzani', 'student12@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (20, 'Chaimae Benali', 'student13@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (21, 'Bilal Tahiri', 'student14@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (22, 'Hajar El Amrani', 'student15@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (23, 'Nour Haddad', 'student16@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (24, 'Sara Rifi', 'student17@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (25, 'Reda Mansouri', 'student18@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (26, 'Fatima Skalli', 'student19@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (27, 'Rania Zaidi', 'student20@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (28, 'Imane Naciri', 'student21@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (29, 'Oussama Bouzid', 'student22@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (30, 'Hamza Kettani', 'student23@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (31, 'Salma Lahlou', 'student24@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (32, 'Yassine Berrada', 'student25@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (33, 'Mohamed Chakir', 'student26@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (34, 'Khadija Ouazzani', 'student27@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (35, 'Walid Benali', 'student28@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (36, 'Anas Tahiri', 'student29@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student'),
  (37, 'Amine El Amrani', 'student30@school.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student');

INSERT INTO classes (id, name, level) VALUES
  (1, 'Class 1A', 'Primary'),
  (2, 'Class 2A', 'Primary'),
  (3, 'Class 3A', 'Middle'),
  (4, 'Class 4A', 'Middle'),
  (5, 'Class 5A', 'High');

INSERT INTO teachers (id, user_id, phone, speciality, hire_date) VALUES
  (1, 2, '06 61 00 00 01', 'Mathematics', '2011-09-01'),
  (2, 3, '06 61 00 00 02', 'Physics', '2012-09-01'),
  (3, 4, '06 61 00 00 03', 'French', '2013-09-01'),
  (4, 5, '06 61 00 00 04', 'English', '2014-09-01'),
  (5, 6, '06 61 00 00 05', 'Computer Science', '2015-09-01'),
  (6, 7, '06 61 00 00 06', 'History', '2016-09-01');

INSERT INTO subjects (id, name, code) VALUES
  (1, 'Mathematics', 'MATH'),
  (2, 'Physics', 'PHY'),
  (3, 'French', 'FRA'),
  (4, 'English', 'ENG'),
  (5, 'Computer Science', 'CS'),
  (6, 'History', 'HIS');

INSERT INTO class_subjects (id, class_id, subject_id, teacher_id) VALUES
  (1, 1, 1, 1),
  (2, 1, 2, 2),
  (3, 1, 3, 3),
  (4, 1, 4, 4),
  (5, 1, 5, 5),
  (6, 1, 6, 6),
  (7, 2, 1, 1),
  (8, 2, 2, 2),
  (9, 2, 3, 3),
  (10, 2, 4, 4),
  (11, 2, 5, 5),
  (12, 2, 6, 6),
  (13, 3, 1, 1),
  (14, 3, 2, 2),
  (15, 3, 3, 3),
  (16, 3, 4, 4),
  (17, 3, 5, 5),
  (18, 3, 6, 6),
  (19, 4, 1, 1),
  (20, 4, 2, 2),
  (21, 4, 3, 3),
  (22, 4, 4, 4),
  (23, 4, 5, 5),
  (24, 4, 6, 6),
  (25, 5, 1, 1),
  (26, 5, 2, 2),
  (27, 5, 3, 3),
  (28, 5, 4, 4),
  (29, 5, 5, 5),
  (30, 5, 6, 6);

INSERT INTO dormitories (id, name, capacity) VALUES
  (1, 'Dortoir Atlas', 20),
  (2, 'Dortoir Rif', 20),
  (3, 'Dortoir Sahara', 15);

INSERT INTO transport_routes (id, name, vehicle, driver, fare) VALUES
  (1, 'Ligne Centre-Ville', 'Bus 12', 'Said Moujahid', 150.0),
  (2, 'Ligne Nord', 'Minibus 3', 'Rachid Amar', 200.0),
  (3, 'Ligne Port', 'Bus 7', 'Hicham Lotfi', 180.0);

INSERT INTO students (id, user_id, admission_no, first_name, last_name, gender, birth_date, phone, emergency_contact, class_id, dormitory_id, transport_id, status, created_at) VALUES
  (1, 8, 'ADM2026001', 'Meryem', 'Haddad', 'Female', '2008-04-02', '06 62 81 27 47', 'Contact urgence 1: 06 63 63 28 79', 1, 3, 3, 'Active', '2026-02-19 09:00:00'),
  (2, 9, 'ADM2026002', 'Ayoub', 'Rifi', 'Male', '2008-10-19', '06 62 91 34 57', 'Contact urgence 2: 06 63 22 80 18', 2, 1, 1, 'Active', '2026-01-20 09:00:00'),
  (3, 10, 'ADM2026003', 'Douae', 'Mansouri', 'Female', '2013-09-14', '06 62 50 69 84', 'Contact urgence 3: 06 63 68 56 48', 3, NULL, 3, 'Active', '2026-04-26 09:00:00'),
  (4, 11, 'ADM2026004', 'Kawtar', 'Skalli', 'Female', '2008-10-10', '06 62 77 73 53', 'Contact urgence 4: 06 63 67 46 87', 4, NULL, 1, 'Active', '2026-02-04 09:00:00'),
  (5, 12, 'ADM2026005', 'Ilyas', 'Zaidi', 'Male', '2009-06-05', '06 62 72 63 15', 'Contact urgence 5: 06 63 95 19 81', 5, 3, 3, 'Active', '2026-06-11 09:00:00'),
  (6, 13, 'ADM2026006', 'Zineb', 'Naciri', 'Female', '2012-08-03', '06 62 21 44 70', 'Contact urgence 6: 06 63 99 95 18', 1, 1, 3, 'Active', '2026-01-24 09:00:00'),
  (7, 14, 'ADM2026007', 'Mehdi', 'Bouzid', 'Male', '2010-12-13', '06 62 95 54 12', 'Contact urgence 7: 06 63 69 55 31', 2, 1, 3, 'Active', '2026-02-16 09:00:00'),
  (8, 15, 'ADM2026008', 'Ahmed', 'Kettani', 'Male', '2010-03-24', '06 62 41 60 60', 'Contact urgence 8: 06 63 73 20 31', 3, NULL, 1, 'Active', '2026-08-13 09:00:00'),
  (9, 16, 'ADM2026009', 'Saad', 'Lahlou', 'Male', '2009-07-28', '06 62 80 45 63', 'Contact urgence 9: 06 63 55 97 58', 4, 3, 2, 'Active', '2026-04-05 09:00:00'),
  (10, 17, 'ADM2026010', 'Zakaria', 'Berrada', 'Male', '2009-04-22', '06 62 39 11 72', 'Contact urgence 10: 06 63 85 33 43', 5, NULL, 1, 'Active', '2026-05-01 09:00:00'),
  (11, 18, 'ADM2026011', 'Lina', 'Chakir', 'Female', '2012-06-20', '06 62 82 50 26', 'Contact urgence 11: 06 63 98 75 89', 1, NULL, 3, 'Active', '2026-01-15 09:00:00'),
  (12, 19, 'ADM2026012', 'Aya', 'Ouazzani', 'Female', '2011-07-13', '06 62 23 71 91', 'Contact urgence 12: 06 63 61 17 34', 2, 3, 3, 'Active', '2026-02-07 09:00:00'),
  (13, 20, 'ADM2026013', 'Chaimae', 'Benali', 'Female', '2008-06-20', '06 62 16 23 10', 'Contact urgence 13: 06 63 82 29 78', 3, 2, 1, 'Active', '2026-02-12 09:00:00'),
  (14, 21, 'ADM2026014', 'Bilal', 'Tahiri', 'Male', '2008-04-20', '06 62 58 29 91', 'Contact urgence 14: 06 63 42 54 87', 4, 3, NULL, 'Active', '2026-06-16 09:00:00'),
  (15, 22, 'ADM2026015', 'Hajar', 'El Amrani', 'Female', '2011-08-16', '06 62 71 49 20', 'Contact urgence 15: 06 63 28 23 53', 5, NULL, NULL, 'Active', '2026-05-16 09:00:00'),
  (16, 23, 'ADM2026016', 'Nour', 'Haddad', 'Female', '2009-09-12', '06 62 28 98 79', 'Contact urgence 16: 06 63 13 77 48', 1, NULL, NULL, 'Active', '2026-02-23 09:00:00'),
  (17, 24, 'ADM2026017', 'Sara', 'Rifi', 'Female', '2009-06-25', '06 62 38 78 79', 'Contact urgence 17: 06 63 74 52 91', 2, 1, 2, 'Active', '2026-04-20 09:00:00'),
  (18, 25, 'ADM2026018', 'Reda', 'Mansouri', 'Male', '2011-12-26', '06 62 39 35 76', 'Contact urgence 18: 06 63 73 55 13', 3, NULL, 1, 'Active', '2026-01-26 09:00:00'),
  (19, 26, 'ADM2026019', 'Fatima', 'Skalli', 'Female', '2010-04-23', '06 62 87 54 67', 'Contact urgence 19: 06 63 54 56 20', 4, 1, 3, 'Active', '2026-04-04 09:00:00'),
  (20, 27, 'ADM2026020', 'Rania', 'Zaidi', 'Female', '2009-06-07', '06 62 71 89 88', 'Contact urgence 20: 06 63 10 71 93', 5, NULL, 3, 'Active', '2026-06-26 09:00:00'),
  (21, 28, 'ADM2026021', 'Imane', 'Naciri', 'Female', '2011-12-25', '06 62 35 71 32', 'Contact urgence 21: 06 63 65 91 52', 1, NULL, NULL, 'Active', '2026-02-26 09:00:00'),
  (22, 29, 'ADM2026022', 'Oussama', 'Bouzid', 'Male', '2011-12-03', '06 62 30 31 26', 'Contact urgence 22: 06 63 13 29 85', 2, 2, 3, 'Active', '2026-08-26 09:00:00'),
  (23, 30, 'ADM2026023', 'Hamza', 'Kettani', 'Male', '2013-06-05', '06 62 80 80 26', 'Contact urgence 23: 06 63 12 11 93', 3, NULL, 3, 'Active', '2026-02-17 09:00:00'),
  (24, 31, 'ADM2026024', 'Salma', 'Lahlou', 'Female', '2009-04-01', '06 62 42 37 47', 'Contact urgence 24: 06 63 74 40 85', 4, NULL, 3, 'Active', '2026-06-09 09:00:00'),
  (25, 32, 'ADM2026025', 'Yassine', 'Berrada', 'Male', '2009-01-24', '06 62 55 68 94', 'Contact urgence 25: 06 63 84 76 63', 5, 3, 3, 'Active', '2026-09-05 09:00:00'),
  (26, 33, 'ADM2026026', 'Mohamed', 'Chakir', 'Male', '2012-09-01', '06 62 66 33 87', 'Contact urgence 26: 06 63 10 29 32', 1, 3, 1, 'Active', '2026-03-16 09:00:00'),
  (27, 34, 'ADM2026027', 'Khadija', 'Ouazzani', 'Female', '2012-01-11', '06 62 97 76 77', 'Contact urgence 27: 06 63 81 71 23', 2, 3, NULL, 'Active', '2026-09-02 09:00:00'),
  (28, 35, 'ADM2026028', 'Walid', 'Benali', 'Male', '2010-01-25', '06 62 22 74 67', 'Contact urgence 28: 06 63 81 13 18', 3, NULL, 1, 'Active', '2026-08-11 09:00:00'),
  (29, 36, 'ADM2026029', 'Anas', 'Tahiri', 'Male', '2013-05-15', '06 62 75 78 71', 'Contact urgence 29: 06 63 74 41 99', 4, 3, 1, 'Active', '2026-09-09 09:00:00'),
  (30, 37, 'ADM2026030', 'Amine', 'El Amrani', 'Male', '2011-03-14', '06 62 25 60 66', 'Contact urgence 30: 06 63 50 19 95', 5, 3, 1, 'Active', '2026-04-14 09:00:00');

INSERT INTO class_routine (id, class_id, subject_id, teacher_id, day_name, start_time, end_time, room) VALUES
  (1, 1, 2, 2, 'Monday', '08:00:00', '09:00:00', 'Room 101'),
  (2, 1, 3, 3, 'Monday', '09:00:00', '10:00:00', 'Room 101'),
  (3, 1, 4, 4, 'Monday', '10:15:00', '11:15:00', 'Room 101'),
  (4, 1, 5, 5, 'Monday', '11:15:00', '12:15:00', 'Room 101'),
  (5, 1, 4, 4, 'Tuesday', '08:00:00', '09:00:00', 'Room 101'),
  (6, 1, 5, 5, 'Tuesday', '09:00:00', '10:00:00', 'Room 101'),
  (7, 1, 6, 6, 'Tuesday', '10:15:00', '11:15:00', 'Room 101'),
  (8, 1, 1, 1, 'Tuesday', '11:15:00', '12:15:00', 'Room 101'),
  (9, 1, 6, 6, 'Wednesday', '08:00:00', '09:00:00', 'Room 101'),
  (10, 1, 1, 1, 'Wednesday', '09:00:00', '10:00:00', 'Room 101'),
  (11, 1, 2, 2, 'Wednesday', '10:15:00', '11:15:00', 'Room 101'),
  (12, 1, 3, 3, 'Wednesday', '11:15:00', '12:15:00', 'Room 101'),
  (13, 1, 2, 2, 'Thursday', '08:00:00', '09:00:00', 'Room 101'),
  (14, 1, 3, 3, 'Thursday', '09:00:00', '10:00:00', 'Room 101'),
  (15, 1, 4, 4, 'Thursday', '10:15:00', '11:15:00', 'Room 101'),
  (16, 1, 5, 5, 'Thursday', '11:15:00', '12:15:00', 'Room 101'),
  (17, 1, 4, 4, 'Friday', '08:00:00', '09:00:00', 'Room 101'),
  (18, 1, 5, 5, 'Friday', '09:00:00', '10:00:00', 'Room 101'),
  (19, 1, 6, 6, 'Friday', '10:15:00', '11:15:00', 'Room 101'),
  (20, 1, 1, 1, 'Friday', '11:15:00', '12:15:00', 'Room 101'),
  (21, 2, 3, 3, 'Monday', '08:00:00', '09:00:00', 'Room 102'),
  (22, 2, 4, 4, 'Monday', '09:00:00', '10:00:00', 'Room 102'),
  (23, 2, 5, 5, 'Monday', '10:15:00', '11:15:00', 'Room 102'),
  (24, 2, 6, 6, 'Monday', '11:15:00', '12:15:00', 'Room 102'),
  (25, 2, 5, 5, 'Tuesday', '08:00:00', '09:00:00', 'Room 102'),
  (26, 2, 6, 6, 'Tuesday', '09:00:00', '10:00:00', 'Room 102'),
  (27, 2, 1, 1, 'Tuesday', '10:15:00', '11:15:00', 'Room 102'),
  (28, 2, 2, 2, 'Tuesday', '11:15:00', '12:15:00', 'Room 102'),
  (29, 2, 1, 1, 'Wednesday', '08:00:00', '09:00:00', 'Room 102'),
  (30, 2, 2, 2, 'Wednesday', '09:00:00', '10:00:00', 'Room 102'),
  (31, 2, 3, 3, 'Wednesday', '10:15:00', '11:15:00', 'Room 102'),
  (32, 2, 4, 4, 'Wednesday', '11:15:00', '12:15:00', 'Room 102'),
  (33, 2, 3, 3, 'Thursday', '08:00:00', '09:00:00', 'Room 102'),
  (34, 2, 4, 4, 'Thursday', '09:00:00', '10:00:00', 'Room 102'),
  (35, 2, 5, 5, 'Thursday', '10:15:00', '11:15:00', 'Room 102'),
  (36, 2, 6, 6, 'Thursday', '11:15:00', '12:15:00', 'Room 102'),
  (37, 2, 5, 5, 'Friday', '08:00:00', '09:00:00', 'Room 102'),
  (38, 2, 6, 6, 'Friday', '09:00:00', '10:00:00', 'Room 102'),
  (39, 2, 1, 1, 'Friday', '10:15:00', '11:15:00', 'Room 102'),
  (40, 2, 2, 2, 'Friday', '11:15:00', '12:15:00', 'Room 102'),
  (41, 3, 4, 4, 'Monday', '08:00:00', '09:00:00', 'Room 103'),
  (42, 3, 5, 5, 'Monday', '09:00:00', '10:00:00', 'Room 103'),
  (43, 3, 6, 6, 'Monday', '10:15:00', '11:15:00', 'Room 103'),
  (44, 3, 1, 1, 'Monday', '11:15:00', '12:15:00', 'Room 103'),
  (45, 3, 6, 6, 'Tuesday', '08:00:00', '09:00:00', 'Room 103'),
  (46, 3, 1, 1, 'Tuesday', '09:00:00', '10:00:00', 'Room 103'),
  (47, 3, 2, 2, 'Tuesday', '10:15:00', '11:15:00', 'Room 103'),
  (48, 3, 3, 3, 'Tuesday', '11:15:00', '12:15:00', 'Room 103'),
  (49, 3, 2, 2, 'Wednesday', '08:00:00', '09:00:00', 'Room 103'),
  (50, 3, 3, 3, 'Wednesday', '09:00:00', '10:00:00', 'Room 103'),
  (51, 3, 4, 4, 'Wednesday', '10:15:00', '11:15:00', 'Room 103'),
  (52, 3, 5, 5, 'Wednesday', '11:15:00', '12:15:00', 'Room 103'),
  (53, 3, 4, 4, 'Thursday', '08:00:00', '09:00:00', 'Room 103'),
  (54, 3, 5, 5, 'Thursday', '09:00:00', '10:00:00', 'Room 103'),
  (55, 3, 6, 6, 'Thursday', '10:15:00', '11:15:00', 'Room 103'),
  (56, 3, 1, 1, 'Thursday', '11:15:00', '12:15:00', 'Room 103'),
  (57, 3, 6, 6, 'Friday', '08:00:00', '09:00:00', 'Room 103'),
  (58, 3, 1, 1, 'Friday', '09:00:00', '10:00:00', 'Room 103'),
  (59, 3, 2, 2, 'Friday', '10:15:00', '11:15:00', 'Room 103'),
  (60, 3, 3, 3, 'Friday', '11:15:00', '12:15:00', 'Room 103'),
  (61, 4, 5, 5, 'Monday', '08:00:00', '09:00:00', 'Room 104'),
  (62, 4, 6, 6, 'Monday', '09:00:00', '10:00:00', 'Room 104'),
  (63, 4, 1, 1, 'Monday', '10:15:00', '11:15:00', 'Room 104'),
  (64, 4, 2, 2, 'Monday', '11:15:00', '12:15:00', 'Room 104'),
  (65, 4, 1, 1, 'Tuesday', '08:00:00', '09:00:00', 'Room 104'),
  (66, 4, 2, 2, 'Tuesday', '09:00:00', '10:00:00', 'Room 104'),
  (67, 4, 3, 3, 'Tuesday', '10:15:00', '11:15:00', 'Room 104'),
  (68, 4, 4, 4, 'Tuesday', '11:15:00', '12:15:00', 'Room 104'),
  (69, 4, 3, 3, 'Wednesday', '08:00:00', '09:00:00', 'Room 104'),
  (70, 4, 4, 4, 'Wednesday', '09:00:00', '10:00:00', 'Room 104'),
  (71, 4, 5, 5, 'Wednesday', '10:15:00', '11:15:00', 'Room 104'),
  (72, 4, 6, 6, 'Wednesday', '11:15:00', '12:15:00', 'Room 104'),
  (73, 4, 5, 5, 'Thursday', '08:00:00', '09:00:00', 'Room 104'),
  (74, 4, 6, 6, 'Thursday', '09:00:00', '10:00:00', 'Room 104'),
  (75, 4, 1, 1, 'Thursday', '10:15:00', '11:15:00', 'Room 104'),
  (76, 4, 2, 2, 'Thursday', '11:15:00', '12:15:00', 'Room 104'),
  (77, 4, 1, 1, 'Friday', '08:00:00', '09:00:00', 'Room 104'),
  (78, 4, 2, 2, 'Friday', '09:00:00', '10:00:00', 'Room 104'),
  (79, 4, 3, 3, 'Friday', '10:15:00', '11:15:00', 'Room 104'),
  (80, 4, 4, 4, 'Friday', '11:15:00', '12:15:00', 'Room 104'),
  (81, 5, 6, 6, 'Monday', '08:00:00', '09:00:00', 'Room 105'),
  (82, 5, 1, 1, 'Monday', '09:00:00', '10:00:00', 'Room 105'),
  (83, 5, 2, 2, 'Monday', '10:15:00', '11:15:00', 'Room 105'),
  (84, 5, 3, 3, 'Monday', '11:15:00', '12:15:00', 'Room 105'),
  (85, 5, 2, 2, 'Tuesday', '08:00:00', '09:00:00', 'Room 105'),
  (86, 5, 3, 3, 'Tuesday', '09:00:00', '10:00:00', 'Room 105'),
  (87, 5, 4, 4, 'Tuesday', '10:15:00', '11:15:00', 'Room 105'),
  (88, 5, 5, 5, 'Tuesday', '11:15:00', '12:15:00', 'Room 105'),
  (89, 5, 4, 4, 'Wednesday', '08:00:00', '09:00:00', 'Room 105'),
  (90, 5, 5, 5, 'Wednesday', '09:00:00', '10:00:00', 'Room 105'),
  (91, 5, 6, 6, 'Wednesday', '10:15:00', '11:15:00', 'Room 105'),
  (92, 5, 1, 1, 'Wednesday', '11:15:00', '12:15:00', 'Room 105'),
  (93, 5, 6, 6, 'Thursday', '08:00:00', '09:00:00', 'Room 105'),
  (94, 5, 1, 1, 'Thursday', '09:00:00', '10:00:00', 'Room 105'),
  (95, 5, 2, 2, 'Thursday', '10:15:00', '11:15:00', 'Room 105'),
  (96, 5, 3, 3, 'Thursday', '11:15:00', '12:15:00', 'Room 105'),
  (97, 5, 2, 2, 'Friday', '08:00:00', '09:00:00', 'Room 105'),
  (98, 5, 3, 3, 'Friday', '09:00:00', '10:00:00', 'Room 105'),
  (99, 5, 4, 4, 'Friday', '10:15:00', '11:15:00', 'Room 105'),
  (100, 5, 5, 5, 'Friday', '11:15:00', '12:15:00', 'Room 105');

INSERT INTO grades (id, name, min_mark, max_mark, comment) VALUES
  (1, 'A', 16, 20, 'Excellent'),
  (2, 'B', 14, 15.99, 'Tres bien'),
  (3, 'C', 12, 13.99, 'Bien'),
  (4, 'D', 10, 11.99, 'Passable'),
  (5, 'F', 0, 9.99, 'Insuffisant');

INSERT INTO exams (id, name, class_id, exam_date) VALUES
  (1, 'Examen Trimestre 1', 1, '2026-12-10'),
  (2, 'Examen Trimestre 1', 2, '2026-12-10'),
  (3, 'Examen Trimestre 1', 3, '2026-12-10'),
  (4, 'Examen Trimestre 1', 4, '2026-12-10'),
  (5, 'Examen Trimestre 1', 5, '2026-12-10');

INSERT INTO exam_marks (id, exam_id, student_id, subject_id, mark) VALUES
  (1, 1, 1, 1, 6.99),
  (2, 1, 1, 2, 15.04),
  (3, 1, 1, 3, 16.58),
  (4, 1, 1, 4, 18.11),
  (5, 1, 1, 5, 8.09),
  (6, 1, 1, 6, 15.67),
  (7, 2, 2, 1, 14.91),
  (8, 2, 2, 2, 7.93),
  (9, 2, 2, 3, 17.92),
  (10, 2, 2, 4, 19.06),
  (11, 2, 2, 5, 8.96),
  (12, 2, 2, 6, 18.86),
  (13, 3, 3, 1, 11.38),
  (14, 3, 3, 2, 12.58),
  (15, 3, 3, 3, 19.36),
  (16, 3, 3, 4, 17.24),
  (17, 3, 3, 5, 8.18),
  (18, 3, 3, 6, 11.83),
  (19, 4, 4, 1, 12.96),
  (20, 4, 4, 2, 10.58),
  (21, 4, 4, 3, 8.64),
  (22, 4, 4, 4, 10.3),
  (23, 4, 4, 5, 15.75),
  (24, 4, 4, 6, 6.26),
  (25, 5, 5, 1, 13.48),
  (26, 5, 5, 2, 11.95),
  (27, 5, 5, 3, 6.24),
  (28, 5, 5, 4, 10.48),
  (29, 5, 5, 5, 14.42),
  (30, 5, 5, 6, 12.92),
  (31, 1, 6, 1, 6.87),
  (32, 1, 6, 2, 19.3),
  (33, 1, 6, 3, 16.64),
  (34, 1, 6, 4, 19.12),
  (35, 1, 6, 5, 7.41),
  (36, 1, 6, 6, 9.59),
  (37, 2, 7, 1, 6.53),
  (38, 2, 7, 2, 16.52),
  (39, 2, 7, 3, 9.65),
  (40, 2, 7, 4, 7.75),
  (41, 2, 7, 5, 11.7),
  (42, 2, 7, 6, 18.3),
  (43, 3, 8, 1, 17.06),
  (44, 3, 8, 2, 9.49),
  (45, 3, 8, 3, 8.02),
  (46, 3, 8, 4, 18.41),
  (47, 3, 8, 5, 13.7),
  (48, 3, 8, 6, 15.46),
  (49, 4, 9, 1, 7.21),
  (50, 4, 9, 2, 6.78),
  (51, 4, 9, 3, 15.29),
  (52, 4, 9, 4, 11.74),
  (53, 4, 9, 5, 6.98),
  (54, 4, 9, 6, 18.67),
  (55, 5, 10, 1, 14.56),
  (56, 5, 10, 2, 16.82),
  (57, 5, 10, 3, 7.13),
  (58, 5, 10, 4, 17.56),
  (59, 5, 10, 5, 6.9),
  (60, 5, 10, 6, 17.65),
  (61, 1, 11, 1, 12.13),
  (62, 1, 11, 2, 10.58),
  (63, 1, 11, 3, 13.47),
  (64, 1, 11, 4, 18.51),
  (65, 1, 11, 5, 9.62),
  (66, 1, 11, 6, 7.74),
  (67, 2, 12, 1, 13.11),
  (68, 2, 12, 2, 9.22),
  (69, 2, 12, 3, 7.48),
  (70, 2, 12, 4, 8.18),
  (71, 2, 12, 5, 6.68),
  (72, 2, 12, 6, 8.72),
  (73, 3, 13, 1, 10.21),
  (74, 3, 13, 2, 10.12),
  (75, 3, 13, 3, 16.25),
  (76, 3, 13, 4, 9.91),
  (77, 3, 13, 5, 12.75),
  (78, 3, 13, 6, 8.4),
  (79, 4, 14, 1, 10.68),
  (80, 4, 14, 2, 6.25),
  (81, 4, 14, 3, 9.38),
  (82, 4, 14, 4, 6.21),
  (83, 4, 14, 5, 15.9),
  (84, 4, 14, 6, 13.44),
  (85, 5, 15, 1, 8.56),
  (86, 5, 15, 2, 12.41),
  (87, 5, 15, 3, 18.62),
  (88, 5, 15, 4, 7.43),
  (89, 5, 15, 5, 17.06),
  (90, 5, 15, 6, 11.83),
  (91, 1, 16, 1, 12.68),
  (92, 1, 16, 2, 17.27),
  (93, 1, 16, 3, 11.31),
  (94, 1, 16, 4, 12.84),
  (95, 1, 16, 5, 15.28),
  (96, 1, 16, 6, 19.26),
  (97, 2, 17, 1, 10.63),
  (98, 2, 17, 2, 17.24),
  (99, 2, 17, 3, 15.54),
  (100, 2, 17, 4, 14.59),
  (101, 2, 17, 5, 11.46),
  (102, 2, 17, 6, 10.69),
  (103, 3, 18, 1, 6.73),
  (104, 3, 18, 2, 7.75),
  (105, 3, 18, 3, 6.95),
  (106, 3, 18, 4, 16.0),
  (107, 3, 18, 5, 9.45),
  (108, 3, 18, 6, 8.2),
  (109, 4, 19, 1, 7.14),
  (110, 4, 19, 2, 17.36),
  (111, 4, 19, 3, 17.75),
  (112, 4, 19, 4, 15.05),
  (113, 4, 19, 5, 9.81),
  (114, 4, 19, 6, 9.27),
  (115, 5, 20, 1, 9.96),
  (116, 5, 20, 2, 12.2),
  (117, 5, 20, 3, 8.13),
  (118, 5, 20, 4, 12.02),
  (119, 5, 20, 5, 9.55),
  (120, 5, 20, 6, 18.98),
  (121, 1, 21, 1, 19.13),
  (122, 1, 21, 2, 13.39),
  (123, 1, 21, 3, 9.3),
  (124, 1, 21, 4, 19.04),
  (125, 1, 21, 5, 10.18),
  (126, 1, 21, 6, 10.81),
  (127, 2, 22, 1, 6.01),
  (128, 2, 22, 2, 11.15),
  (129, 2, 22, 3, 12.41),
  (130, 2, 22, 4, 12.79),
  (131, 2, 22, 5, 8.71),
  (132, 2, 22, 6, 12.81),
  (133, 3, 23, 1, 6.07),
  (134, 3, 23, 2, 9.57),
  (135, 3, 23, 3, 7.21),
  (136, 3, 23, 4, 11.39),
  (137, 3, 23, 5, 6.56),
  (138, 3, 23, 6, 6.3),
  (139, 4, 24, 1, 10.11),
  (140, 4, 24, 2, 9.14),
  (141, 4, 24, 3, 13.91),
  (142, 4, 24, 4, 13.14),
  (143, 4, 24, 5, 16.13),
  (144, 4, 24, 6, 14.88),
  (145, 5, 25, 1, 15.67),
  (146, 5, 25, 2, 17.87),
  (147, 5, 25, 3, 11.26),
  (148, 5, 25, 4, 10.4),
  (149, 5, 25, 5, 19.29),
  (150, 5, 25, 6, 8.02),
  (151, 1, 26, 1, 15.78),
  (152, 1, 26, 2, 14.68),
  (153, 1, 26, 3, 6.59),
  (154, 1, 26, 4, 17.28),
  (155, 1, 26, 5, 18.04),
  (156, 1, 26, 6, 14.47),
  (157, 2, 27, 1, 15.91),
  (158, 2, 27, 2, 16.96),
  (159, 2, 27, 3, 7.88),
  (160, 2, 27, 4, 13.07),
  (161, 2, 27, 5, 12.81),
  (162, 2, 27, 6, 17.27),
  (163, 3, 28, 1, 16.86),
  (164, 3, 28, 2, 17.16),
  (165, 3, 28, 3, 13.88),
  (166, 3, 28, 4, 18.05),
  (167, 3, 28, 5, 15.22),
  (168, 3, 28, 6, 15.36),
  (169, 4, 29, 1, 9.1),
  (170, 4, 29, 2, 6.42),
  (171, 4, 29, 3, 7.8),
  (172, 4, 29, 4, 10.87),
  (173, 4, 29, 5, 7.42),
  (174, 4, 29, 6, 17.28),
  (175, 5, 30, 1, 13.54),
  (176, 5, 30, 2, 14.47),
  (177, 5, 30, 3, 14.45),
  (178, 5, 30, 4, 15.19),
  (179, 5, 30, 5, 12.61),
  (180, 5, 30, 6, 6.04);

INSERT INTO attendance (id, student_id, class_id, att_date, status) VALUES
  (1, 1, 1, '2026-10-12', 'Present'),
  (2, 1, 1, '2026-10-13', 'Present'),
  (3, 1, 1, '2026-10-14', 'Present'),
  (4, 1, 1, '2026-10-15', 'Present'),
  (5, 1, 1, '2026-10-16', 'Present'),
  (6, 2, 2, '2026-10-12', 'Present'),
  (7, 2, 2, '2026-10-13', 'Present'),
  (8, 2, 2, '2026-10-14', 'Present'),
  (9, 2, 2, '2026-10-15', 'Present'),
  (10, 2, 2, '2026-10-16', 'Present'),
  (11, 3, 3, '2026-10-12', 'Present'),
  (12, 3, 3, '2026-10-13', 'Present'),
  (13, 3, 3, '2026-10-14', 'Present'),
  (14, 3, 3, '2026-10-15', 'Late'),
  (15, 3, 3, '2026-10-16', 'Present'),
  (16, 4, 4, '2026-10-12', 'Present'),
  (17, 4, 4, '2026-10-13', 'Present'),
  (18, 4, 4, '2026-10-14', 'Present'),
  (19, 4, 4, '2026-10-15', 'Present'),
  (20, 4, 4, '2026-10-16', 'Present'),
  (21, 5, 5, '2026-10-12', 'Present'),
  (22, 5, 5, '2026-10-13', 'Present'),
  (23, 5, 5, '2026-10-14', 'Present'),
  (24, 5, 5, '2026-10-15', 'Present'),
  (25, 5, 5, '2026-10-16', 'Present'),
  (26, 6, 1, '2026-10-12', 'Present'),
  (27, 6, 1, '2026-10-13', 'Present'),
  (28, 6, 1, '2026-10-14', 'Present'),
  (29, 6, 1, '2026-10-15', 'Present'),
  (30, 6, 1, '2026-10-16', 'Present'),
  (31, 7, 2, '2026-10-12', 'Present'),
  (32, 7, 2, '2026-10-13', 'Present'),
  (33, 7, 2, '2026-10-14', 'Present'),
  (34, 7, 2, '2026-10-15', 'Present'),
  (35, 7, 2, '2026-10-16', 'Present'),
  (36, 8, 3, '2026-10-12', 'Present'),
  (37, 8, 3, '2026-10-13', 'Present'),
  (38, 8, 3, '2026-10-14', 'Present'),
  (39, 8, 3, '2026-10-15', 'Absent'),
  (40, 8, 3, '2026-10-16', 'Present'),
  (41, 9, 4, '2026-10-12', 'Late'),
  (42, 9, 4, '2026-10-13', 'Late'),
  (43, 9, 4, '2026-10-14', 'Present'),
  (44, 9, 4, '2026-10-15', 'Present'),
  (45, 9, 4, '2026-10-16', 'Absent'),
  (46, 10, 5, '2026-10-12', 'Late'),
  (47, 10, 5, '2026-10-13', 'Present'),
  (48, 10, 5, '2026-10-14', 'Present'),
  (49, 10, 5, '2026-10-15', 'Present'),
  (50, 10, 5, '2026-10-16', 'Late'),
  (51, 11, 1, '2026-10-12', 'Present'),
  (52, 11, 1, '2026-10-13', 'Present'),
  (53, 11, 1, '2026-10-14', 'Present'),
  (54, 11, 1, '2026-10-15', 'Present'),
  (55, 11, 1, '2026-10-16', 'Late'),
  (56, 12, 2, '2026-10-12', 'Present'),
  (57, 12, 2, '2026-10-13', 'Absent'),
  (58, 12, 2, '2026-10-14', 'Present'),
  (59, 12, 2, '2026-10-15', 'Absent'),
  (60, 12, 2, '2026-10-16', 'Present'),
  (61, 13, 3, '2026-10-12', 'Present'),
  (62, 13, 3, '2026-10-13', 'Absent'),
  (63, 13, 3, '2026-10-14', 'Present'),
  (64, 13, 3, '2026-10-15', 'Present'),
  (65, 13, 3, '2026-10-16', 'Present'),
  (66, 14, 4, '2026-10-12', 'Present'),
  (67, 14, 4, '2026-10-13', 'Present'),
  (68, 14, 4, '2026-10-14', 'Present'),
  (69, 14, 4, '2026-10-15', 'Present'),
  (70, 14, 4, '2026-10-16', 'Present'),
  (71, 15, 5, '2026-10-12', 'Present'),
  (72, 15, 5, '2026-10-13', 'Absent'),
  (73, 15, 5, '2026-10-14', 'Present'),
  (74, 15, 5, '2026-10-15', 'Present'),
  (75, 15, 5, '2026-10-16', 'Absent'),
  (76, 16, 1, '2026-10-12', 'Present'),
  (77, 16, 1, '2026-10-13', 'Late'),
  (78, 16, 1, '2026-10-14', 'Present'),
  (79, 16, 1, '2026-10-15', 'Absent'),
  (80, 16, 1, '2026-10-16', 'Present'),
  (81, 17, 2, '2026-10-12', 'Present'),
  (82, 17, 2, '2026-10-13', 'Present'),
  (83, 17, 2, '2026-10-14', 'Late'),
  (84, 17, 2, '2026-10-15', 'Present'),
  (85, 17, 2, '2026-10-16', 'Present'),
  (86, 18, 3, '2026-10-12', 'Present'),
  (87, 18, 3, '2026-10-13', 'Present'),
  (88, 18, 3, '2026-10-14', 'Present'),
  (89, 18, 3, '2026-10-15', 'Present'),
  (90, 18, 3, '2026-10-16', 'Absent'),
  (91, 19, 4, '2026-10-12', 'Present'),
  (92, 19, 4, '2026-10-13', 'Late'),
  (93, 19, 4, '2026-10-14', 'Present'),
  (94, 19, 4, '2026-10-15', 'Present'),
  (95, 19, 4, '2026-10-16', 'Present'),
  (96, 20, 5, '2026-10-12', 'Present'),
  (97, 20, 5, '2026-10-13', 'Present'),
  (98, 20, 5, '2026-10-14', 'Late'),
  (99, 20, 5, '2026-10-15', 'Absent'),
  (100, 20, 5, '2026-10-16', 'Absent'),
  (101, 21, 1, '2026-10-12', 'Present'),
  (102, 21, 1, '2026-10-13', 'Absent'),
  (103, 21, 1, '2026-10-14', 'Late'),
  (104, 21, 1, '2026-10-15', 'Present'),
  (105, 21, 1, '2026-10-16', 'Present'),
  (106, 22, 2, '2026-10-12', 'Present'),
  (107, 22, 2, '2026-10-13', 'Present'),
  (108, 22, 2, '2026-10-14', 'Present'),
  (109, 22, 2, '2026-10-15', 'Present'),
  (110, 22, 2, '2026-10-16', 'Present'),
  (111, 23, 3, '2026-10-12', 'Present'),
  (112, 23, 3, '2026-10-13', 'Present'),
  (113, 23, 3, '2026-10-14', 'Late'),
  (114, 23, 3, '2026-10-15', 'Present'),
  (115, 23, 3, '2026-10-16', 'Present'),
  (116, 24, 4, '2026-10-12', 'Present'),
  (117, 24, 4, '2026-10-13', 'Present'),
  (118, 24, 4, '2026-10-14', 'Present'),
  (119, 24, 4, '2026-10-15', 'Late'),
  (120, 24, 4, '2026-10-16', 'Present'),
  (121, 25, 5, '2026-10-12', 'Present'),
  (122, 25, 5, '2026-10-13', 'Present'),
  (123, 25, 5, '2026-10-14', 'Present'),
  (124, 25, 5, '2026-10-15', 'Present'),
  (125, 25, 5, '2026-10-16', 'Present'),
  (126, 26, 1, '2026-10-12', 'Present'),
  (127, 26, 1, '2026-10-13', 'Present'),
  (128, 26, 1, '2026-10-14', 'Absent'),
  (129, 26, 1, '2026-10-15', 'Present'),
  (130, 26, 1, '2026-10-16', 'Present'),
  (131, 27, 2, '2026-10-12', 'Absent'),
  (132, 27, 2, '2026-10-13', 'Late'),
  (133, 27, 2, '2026-10-14', 'Present'),
  (134, 27, 2, '2026-10-15', 'Present'),
  (135, 27, 2, '2026-10-16', 'Present'),
  (136, 28, 3, '2026-10-12', 'Present'),
  (137, 28, 3, '2026-10-13', 'Present'),
  (138, 28, 3, '2026-10-14', 'Present'),
  (139, 28, 3, '2026-10-15', 'Present'),
  (140, 28, 3, '2026-10-16', 'Present'),
  (141, 29, 4, '2026-10-12', 'Present'),
  (142, 29, 4, '2026-10-13', 'Absent'),
  (143, 29, 4, '2026-10-14', 'Present'),
  (144, 29, 4, '2026-10-15', 'Present'),
  (145, 29, 4, '2026-10-16', 'Present'),
  (146, 30, 5, '2026-10-12', 'Present'),
  (147, 30, 5, '2026-10-13', 'Present'),
  (148, 30, 5, '2026-10-14', 'Present'),
  (149, 30, 5, '2026-10-15', 'Present'),
  (150, 30, 5, '2026-10-16', 'Present');

INSERT INTO study_materials (id, title, file_name, class_id, subject_id, teacher_id) VALUES
  (1, 'Cours Algebre - Chapitre 1', 'algebre_ch1.pdf', 3, 1, 1),
  (2, 'TP Physique - Mecanique', 'tp_mecanique.pdf', 3, 2, 2),
  (3, 'Grammaire francaise', 'grammaire.pdf', 1, 3, 3),
  (4, 'English Vocabulary Unit 1', 'vocab_u1.pdf', 2, 4, 4),
  (5, 'Introduction a PHP', 'intro_php.pdf', 5, 5, 5),
  (6, 'Histoire du Maroc', 'histoire_maroc.pdf', 4, 6, 6);

INSERT INTO invoices (id, student_id, title, amount, due_date, status) VALUES
  (1, 1, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (2, 2, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (3, 3, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (4, 4, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (5, 5, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (6, 6, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (7, 7, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (8, 8, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (9, 9, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (10, 10, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (11, 11, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (12, 12, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (13, 13, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (14, 14, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (15, 15, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (16, 16, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (17, 17, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (18, 18, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (19, 19, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (20, 20, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (21, 21, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (22, 22, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (23, 23, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (24, 24, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (25, 25, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (26, 26, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (27, 27, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (28, 28, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid'),
  (29, 29, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Paid'),
  (30, 30, 'Frais de scolarite - Trimestre 1', 1500.0, '2026-11-01', 'Unpaid');

INSERT INTO payments (id, invoice_id, amount, method, paid_at) VALUES
  (1, 2, 1500.0, 'Online', '2026-10-09'),
  (2, 5, 1500.0, 'Card', '2026-10-15'),
  (3, 6, 1500.0, 'Card', '2026-10-11'),
  (4, 7, 1500.0, 'Card', '2026-10-14'),
  (5, 10, 1500.0, 'Card', '2026-10-12'),
  (6, 14, 1500.0, 'Cash', '2026-10-07'),
  (7, 17, 1500.0, 'Card', '2026-10-08'),
  (8, 18, 1500.0, 'Cash', '2026-10-04'),
  (9, 19, 1500.0, 'Online', '2026-10-11'),
  (10, 20, 1500.0, 'Online', '2026-10-12'),
  (11, 23, 1500.0, 'Online', '2026-10-13'),
  (12, 24, 1500.0, 'Cash', '2026-10-04'),
  (13, 25, 1500.0, 'Cash', '2026-10-11'),
  (14, 29, 1500.0, 'Card', '2026-10-12');

INSERT INTO accounting (id, type, category, amount, description, entry_date) VALUES
  (1, 'Income', 'Frais de scolarite', 21000.0, 'Paiements recus Trimestre 1', '2026-10-15'),
  (2, 'Expense', 'Salaires', 9000.0, 'Salaires enseignants - Octobre', '2026-10-05'),
  (3, 'Expense', 'Electricite', 650.0, 'Facture electricite', '2026-10-08'),
  (4, 'Expense', 'Fournitures', 420.0, 'Papier et marqueurs', '2026-10-10'),
  (5, 'Income', 'Don', 1200.0, 'Don association des anciens', '2026-10-12');

INSERT INTO events (id, title, description, event_date, location) VALUES
  (1, 'Journee portes ouvertes', 'Presentation de l ecole aux nouvelles familles', '2026-11-05', 'Cour principale'),
  (2, 'Concours de sciences', 'Exposition des projets scientifiques', '2026-11-20', 'Laboratoire'),
  (3, 'Fete de fin de trimestre', 'Spectacle et remise de prix', '2026-12-18', 'Salle polyvalente');

INSERT INTO books (id, title, author, quantity) VALUES
  (1, 'Le Petit Prince', 'Antoine de Saint-Exupery', 5),
  (2, 'Les Miserables', 'Victor Hugo', 3),
  (3, 'Algorithms Unlocked', 'Thomas Cormen', 2),
  (4, 'Physique Generale', 'Halliday', 4),
  (5, 'Histoire du Maroc', 'Abdallah Laroui', 3);

INSERT INTO book_issues (id, book_id, student_id, issue_date, return_date) VALUES
  (1, 1, 1, '2026-10-01', '2026-10-10'),
  (2, 3, 5, '2026-10-08', NULL),
  (3, 2, 9, '2026-10-12', NULL);

INSERT INTO messages (id, sender_id, receiver_id, subject, body) VALUES
  (1, 1, 2, 'Reunion pedagogique', 'Bonjour, reunion vendredi a 14h.'),
  (2, 2, 1, 'Re: Reunion pedagogique', 'Bien recu, je serai present.'),
  (3, 8, 9, 'Question devoir', 'Pouvez-vous expliquer l exercice 3 ?');

INSERT INTO sms_log (id, student_id, exam_id, content) VALUES
  (1, 1, 1, 'Notes Examen Trimestre 1 : voir portail.');

INSERT INTO settings (setting_key, setting_value) VALUES
  ('school_name', 'Student Manager School'),
  ('school_email', 'contact@school.ma'),
  ('school_phone', '0539 00 00 00'),
  ('currency', 'MAD'),
  ('language', 'fr'),
  ('sms_gateway', 'Twilio'),
  ('sms_sender', 'StudentMgr');