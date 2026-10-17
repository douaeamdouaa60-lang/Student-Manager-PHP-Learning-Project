<?php
/* =====================================================================
   STUDENT MANAGER  -  index.php
   Un seul fichier : PHP (logique + donnees) + HTML (affichage).
   Navigation : index.php?page=dashboard | students | teachers | ...
   ===================================================================== */

/* ---------- 1) CONNEXION A LA BASE (PDO) ---------- */
$host = 'localhost';
$db   = 'studentmanager';
$user = 'root';      // WAMP/XAMPP : root
$pass = '';          // WAMP/XAMPP : mot de passe vide
try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    die("Erreur de connexion MySQL : " . $e->getMessage());
}

/* ---------- 2) PETITES FONCTIONS UTILES ---------- */
function e($v) { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }          // securise l'affichage (XSS)
function one($pdo, $sql, $p = []) { $s = $pdo->prepare($sql); $s->execute($p); return $s->fetchColumn(); }  // 1 valeur
function all($pdo, $sql, $p = []) { $s = $pdo->prepare($sql); $s->execute($p); return $s->fetchAll(); }     // plusieurs lignes

// Affiche un tableau HTML a partir de colonnes ['Titre' => 'cle_sql'] et de lignes
function render_table($cols, $rows) {
    echo '<div class="table-wrap"><table><thead><tr>';
    foreach ($cols as $title => $key) echo '<th>' . e($title) . '</th>';
    echo '</tr></thead><tbody>';
    if (!$rows) echo '<tr><td colspan="' . count($cols) . '" class="empty">Aucune donnee</td></tr>';
    foreach ($rows as $r) {
        echo '<tr>';
        foreach ($cols as $key) echo '<td>' . e($r[$key] ?? '') . '</td>';
        echo '</tr>';
    }
    echo '</tbody></table></div>';
}

/* ---------- 3) MENU DE GAUCHE (sidebar) ---------- */
$menu = [
    'dashboard'  => ['Dashboard',        '🏠'],
    'students'   => ['Students',         '🎓'],
    'teachers'   => ['Teachers',         '👩‍🏫'],
    'classes'    => ['Classes',          '🏫'],
    'subjects'   => ['Subjects',         '📚'],
    'routine'    => ['Class Routine',    '🗓️'],
    'exams'      => ['Exams & Grades',   '📝'],
    'marks'      => ['Exam Marks',       '💯'],
    'attendance' => ['Attendance',       '✅'],
    'accounting' => ['Accounting',       '💰'],
    'events'     => ['Events',           '🎉'],
    'library'    => ['Library',          '📖'],
    'dormitory'  => ['Dormitory',        '🛏️'],
    'transport'  => ['Transport',        '🚌'],
    'messages'   => ['Messages',         '✉️'],
    'settings'   => ['Settings',         '⚙️'],
];
$page = $_GET['page'] ?? 'dashboard';
if (!isset($menu[$page])) $page = 'dashboard';

/* ---------- 4) ACTIONS (formulaires POST / suppression) ---------- */
$flash = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'add_student') {
    $st = $pdo->prepare("INSERT INTO students
        (admission_no, first_name, last_name, gender, birth_date, class_id, status)
        VALUES (?,?,?,?,?,?, 'Active')");
    $st->execute([
        trim($_POST['admission_no']), trim($_POST['first_name']), trim($_POST['last_name']),
        $_POST['gender'], $_POST['birth_date'] ?: null, (int)$_POST['class_id'],
    ]);
    header('Location: index.php?page=students&ok=1'); exit;
}
if (($_GET['action'] ?? '') === 'delete_student' && isset($_GET['id'])) {
    $pdo->prepare("DELETE FROM students WHERE id = ?")->execute([(int)$_GET['id']]);
    header('Location: index.php?page=students&ok=2'); exit;
}
if (isset($_GET['ok'])) $flash = $_GET['ok'] == 1 ? 'Etudiant ajoute avec succes.' : 'Etudiant supprime.';
$schoolName = one($pdo, "SELECT setting_value FROM settings WHERE setting_key='school_name'");
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Student Manager - <?= e($menu[$page][0]) ?></title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="layout">

  <!-- ================= SIDEBAR : LOGO + MENU ================= -->
  <aside class="sidebar">
    <a class="logo" href="index.php">
      <!-- Logo en SVG : chapeau de diplome + livre, dessine en HTML pur -->
      <svg class="logo-icon" viewBox="0 0 48 48" width="42" height="42" aria-hidden="true">
        <rect width="48" height="48" rx="12" fill="#3f6b5a"/>
        <path d="M24 11 5 20l19 9 19-9z" fill="#fff"/>
        <path d="M13 25v8c0 2 5 5 11 5s11-3 11-5v-8l-11 5z" fill="#cfe5dc"/>
        <rect x="41" y="20" width="2.5" height="13" rx="1.2" fill="#fff"/>
      </svg>
      <span class="logo-text">Student<b>Manager</b></span>
    </a>
    <nav>
      <?php foreach ($menu as $key => $item): ?>
        <a href="index.php?page=<?= $key ?>" class="<?= $page === $key ? 'active' : '' ?>">
          <span class="ico"><?= $item[1] ?></span> <?= e($item[0]) ?>
        </a>
      <?php endforeach; ?>
    </nav>
  </aside>

  <!-- ================= CONTENU PRINCIPAL ================= -->
  <main class="content">
    <?php if ($flash): ?><div class="flash"><?= e($flash) ?></div><?php endif; ?>

<?php /* ================= PAGE : DASHBOARD ================= */
if ($page === 'dashboard'):
    $totalStudents = one($pdo, "SELECT COUNT(*) FROM students");
    $totalTeachers = one($pdo, "SELECT COUNT(*) FROM teachers");
    $totalClasses  = one($pdo, "SELECT COUNT(*) FROM classes");
    $unpaid        = one($pdo, "SELECT COALESCE(SUM(amount),0) FROM invoices WHERE status='Unpaid'");
    $income        = one($pdo, "SELECT COALESCE(SUM(amount),0) FROM accounting WHERE type='Income'");
    $expense       = one($pdo, "SELECT COALESCE(SUM(amount),0) FROM accounting WHERE type='Expense'");
    $lastDay       = one($pdo, "SELECT MAX(att_date) FROM attendance");
    $attStats      = all($pdo, "SELECT status, COUNT(*) n FROM attendance WHERE att_date = ? GROUP BY status", [$lastDay]);
    $perClass      = all($pdo, "SELECT c.name, COUNT(s.id) n FROM classes c LEFT JOIN students s ON s.class_id=c.id GROUP BY c.id ORDER BY c.id");
    $events        = all($pdo, "SELECT title, event_date, location FROM events ORDER BY event_date LIMIT 4");
    $recent        = all($pdo, "SELECT s.first_name, s.last_name, c.name class_name, s.status FROM students s JOIN classes c ON c.id=s.class_id ORDER BY s.created_at DESC LIMIT 5");
?>
    <header class="page-head">
      <p class="eyebrow">DASHBOARD OVERVIEW</p>
      <h1>Bienvenue sur <?= e($schoolName) ?></h1>
      <p class="muted">Vue d'ensemble de l'ecole : effectifs, finances, presences et evenements.</p>
    </header>

    <section class="cards">
      <div class="card"><h3>Total Students</h3><small>Tous statuts</small><div class="big"><?= $totalStudents ?></div></div>
      <div class="card"><h3>Teachers</h3><small>Enseignants</small><div class="big"><?= $totalTeachers ?></div></div>
      <div class="card"><h3>Classes</h3><small>Classes actives</small><div class="big"><?= $totalClasses ?></div></div>
      <div class="card"><h3>Unpaid invoices</h3><small>MAD a encaisser</small><div class="big"><?= number_format($unpaid, 0, ',', ' ') ?></div></div>
    </section>

    <section class="grid-2">
      <div class="panel">
        <h2>Students par classe</h2>
        <?php $max = max(array_column($perClass, 'n') ?: [1]); foreach ($perClass as $c): ?>
          <div class="bar-row">
            <span><?= e($c['name']) ?></span>
            <div class="bar"><i style="width:<?= round($c['n'] / $max * 100) ?>%"></i></div>
            <b><?= $c['n'] ?></b>
          </div>
        <?php endforeach; ?>
      </div>
      <div class="panel">
        <h2>Presences (<?= e($lastDay) ?>)</h2>
        <?php foreach ($attStats as $a): ?>
          <div class="bar-row"><span><?= e($a['status']) ?></span><div class="bar"><i class="<?= strtolower($a['status']) ?>" style="width:<?= round($a['n'] / max(1, $totalStudents) * 100) ?>%"></i></div><b><?= $a['n'] ?></b></div>
        <?php endforeach; ?>
        <h2 class="mt">Finances</h2>
        <p>Revenus : <b class="ok"><?= number_format($income, 0, ',', ' ') ?> MAD</b> &nbsp;|&nbsp; Depenses : <b class="ko"><?= number_format($expense, 0, ',', ' ') ?> MAD</b></p>
      </div>
    </section>

    <section class="grid-2">
      <div class="panel"><h2>Derniers etudiants</h2>
        <?php render_table(['Prenom' => 'first_name', 'Nom' => 'last_name', 'Classe' => 'class_name', 'Statut' => 'status'], $recent); ?>
      </div>
      <div class="panel"><h2>Prochains evenements</h2>
        <?php render_table(['Evenement' => 'title', 'Date' => 'event_date', 'Lieu' => 'location'], $events); ?>
      </div>
    </section>

<?php /* ================= PAGE : STUDENTS (comme l'image 4) ================= */
elseif ($page === 'students'):
    $q      = trim($_GET['q'] ?? '');
    $classF = (int)($_GET['class_id'] ?? 0);
    $statF  = $_GET['status'] ?? '';
    $sql = "SELECT s.*, c.name AS class_name FROM students s JOIN classes c ON c.id=s.class_id WHERE 1=1";
    $par = [];
    if ($q !== '')     { $sql .= " AND (s.first_name LIKE ? OR s.last_name LIKE ? OR s.admission_no LIKE ?)"; array_push($par, "%$q%", "%$q%", "%$q%"); }
    if ($classF)       { $sql .= " AND s.class_id = ?"; $par[] = $classF; }
    if ($statF !== '') { $sql .= " AND s.status = ?";   $par[] = $statF; }
    $sql .= " ORDER BY s.id";
    $students = all($pdo, $sql, $par);
    $classes  = all($pdo, "SELECT id, name FROM classes ORDER BY name");
    $total  = one($pdo, "SELECT COUNT(*) FROM students");
    $active = one($pdo, "SELECT COUNT(*) FROM students WHERE status='Active'");
    $male   = one($pdo, "SELECT COUNT(*) FROM students WHERE gender='Male'");
    $female = one($pdo, "SELECT COUNT(*) FROM students WHERE gender='Female'");
?>
    <header class="page-head">
      <p class="eyebrow">STUDENT MANAGEMENT</p>
      <h1>Manage student records and information</h1>
      <p class="muted">Keep enrollment, emergency details, and status tidy in one place.</p>
      <div class="actions">
        <button class="pill">Export as ▾</button>
        <button class="pill">Bulk Upload</button>
        <button class="pill">Bulk Enroll</button>
        <button class="pill">Promote Students</button>
        <a class="btn" href="#add">+ Add Student</a>
      </div>
    </header>

    <section class="cards">
      <div class="card"><h3>Total Students</h3><small>Active &amp; pending</small><div class="big"><?= $total ?></div></div>
      <div class="card"><h3>Active</h3><small>Currently enrolled</small><div class="big"><?= $active ?> <span class="badge">Active</span></div></div>
      <div class="card"><h3>Male</h3><div class="big"><?= $male ?></div></div>
      <div class="card"><h3>Female</h3><div class="big"><?= $female ?></div></div>
    </section>

    <section class="panel">
      <h2>All Students</h2>
      <p class="muted"><?= count($students) ?> students found</p>
      <!-- Formulaire de recherche/filtre : methode GET = les filtres apparaissent dans l'URL -->
      <form class="filters" method="get">
        <input type="hidden" name="page" value="students">
        <input type="text" name="q" placeholder="Search by name, admission no" value="<?= e($q) ?>">
        <select name="class_id"><option value="0">Select Class</option>
          <?php foreach ($classes as $c): ?><option value="<?= $c['id'] ?>" <?= $classF == $c['id'] ? 'selected' : '' ?>><?= e($c['name']) ?></option><?php endforeach; ?>
        </select>
        <select name="status"><option value="">Select Status</option>
          <?php foreach (['Active', 'Pending', 'Inactive'] as $s): ?><option <?= $statF === $s ? 'selected' : '' ?>><?= $s ?></option><?php endforeach; ?>
        </select>
        <button class="pill" type="submit">Filter</button>
      </form>

      <div class="table-wrap"><table>
        <thead><tr><th>#</th><th>Student</th><th>Status</th><th>Gender</th><th>Class</th><th>Date created</th><th>Actions</th></tr></thead>
        <tbody>
        <?php foreach ($students as $s): ?>
          <tr>
            <td><?= $s['id'] ?></td>
            <td><b><?= e($s['first_name'] . ' ' . $s['last_name']) ?></b><br><small><?= e($s['admission_no']) ?></small></td>
            <td><span class="badge <?= strtolower($s['status']) ?>"><?= e($s['status']) ?></span></td>
            <td><?= e($s['gender']) ?></td>
            <td><?= e($s['class_name']) ?></td>
            <td><?= e(substr($s['created_at'], 0, 10)) ?></td>
            <td><a class="del" href="index.php?page=students&action=delete_student&id=<?= $s['id'] ?>" onclick="return confirm('Supprimer cet etudiant ?')">Delete</a></td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table></div>
    </section>

    <section class="panel" id="add">
      <h2>Add Student</h2>
      <form method="post" class="form-grid">
        <input type="hidden" name="action" value="add_student">
        <label>Admission No<input name="admission_no" required placeholder="ADM2026031"></label>
        <label>First name<input name="first_name" required></label>
        <label>Last name<input name="last_name" required></label>
        <label>Gender<select name="gender"><option>Male</option><option>Female</option></select></label>
        <label>Birth date<input type="date" name="birth_date"></label>
        <label>Class<select name="class_id"><?php foreach ($classes as $c): ?><option value="<?= $c['id'] ?>"><?= e($c['name']) ?></option><?php endforeach; ?></select></label>
        <button class="btn" type="submit">Save student</button>
      </form>
    </section>

<?php /* ================= PAGE : TEACHERS ================= */
elseif ($page === 'teachers'):
    $rows = all($pdo, "SELECT t.id, u.full_name, u.email, t.phone, t.speciality, t.hire_date FROM teachers t JOIN users u ON u.id=t.user_id ORDER BY t.id");
?>
    <header class="page-head"><p class="eyebrow">TEACHER MANAGEMENT</p><h1>Teachers</h1></header>
    <section class="panel"><?php render_table(['#' => 'id', 'Name' => 'full_name', 'Email' => 'email', 'Phone' => 'phone', 'Speciality' => 'speciality', 'Hired' => 'hire_date'], $rows); ?></section>

<?php /* ================= PAGE : CLASSES ================= */
elseif ($page === 'classes'):
    $rows = all($pdo, "SELECT c.id, c.name, c.level, COUNT(s.id) AS nb FROM classes c LEFT JOIN students s ON s.class_id=c.id GROUP BY c.id ORDER BY c.id");
?>
    <header class="page-head"><p class="eyebrow">ACADEMICS</p><h1>Classes</h1></header>
    <section class="panel"><?php render_table(['#' => 'id', 'Class' => 'name', 'Level' => 'level', 'Students' => 'nb'], $rows); ?></section>

<?php /* ================= PAGE : SUBJECTS ================= */
elseif ($page === 'subjects'):
    $rows = all($pdo, "SELECT sub.code, sub.name, c.name AS class_name, u.full_name AS teacher
                       FROM class_subjects cs
                       JOIN subjects sub ON sub.id=cs.subject_id
                       JOIN classes  c   ON c.id=cs.class_id
                       JOIN teachers t   ON t.id=cs.teacher_id
                       JOIN users    u   ON u.id=t.user_id
                       ORDER BY c.id, sub.name");
?>
    <header class="page-head"><p class="eyebrow">ACADEMICS</p><h1>Subjects per class</h1></header>
    <section class="panel"><?php render_table(['Code' => 'code', 'Subject' => 'name', 'Class' => 'class_name', 'Teacher' => 'teacher'], $rows); ?></section>

<?php /* ================= PAGE : CLASS ROUTINE ================= */
elseif ($page === 'routine'):
    $classId = (int)($_GET['class_id'] ?? 1);
    $classes = all($pdo, "SELECT id, name FROM classes");
    $rows = all($pdo, "SELECT r.day_name, CONCAT(TIME_FORMAT(r.start_time,'%H:%i'),' - ',TIME_FORMAT(r.end_time,'%H:%i')) AS slot, sub.name AS subject, u.full_name AS teacher, r.room
                       FROM class_routine r
                       JOIN subjects sub ON sub.id=r.subject_id
                       JOIN teachers t ON t.id=r.teacher_id
                       JOIN users u ON u.id=t.user_id
                       WHERE r.class_id = ?
                       ORDER BY FIELD(r.day_name,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'), r.start_time", [$classId]);
?>
    <header class="page-head"><p class="eyebrow">TIMETABLE</p><h1>Class routine</h1>
      <form method="get" class="filters"><input type="hidden" name="page" value="routine">
        <select name="class_id" onchange="this.form.submit()"><?php foreach ($classes as $c): ?><option value="<?= $c['id'] ?>" <?= $classId == $c['id'] ? 'selected' : '' ?>><?= e($c['name']) ?></option><?php endforeach; ?></select>
      </form></header>
    <section class="panel"><?php render_table(['Day' => 'day_name', 'Time' => 'slot', 'Subject' => 'subject', 'Teacher' => 'teacher', 'Room' => 'room'], $rows); ?></section>

<?php /* ================= PAGE : EXAMS & GRADES ================= */
elseif ($page === 'exams'):
    $exams  = all($pdo, "SELECT e.id, e.name, c.name AS class_name, e.exam_date FROM exams e JOIN classes c ON c.id=e.class_id ORDER BY e.exam_date");
    $grades = all($pdo, "SELECT name, min_mark, max_mark, comment FROM grades ORDER BY min_mark DESC");
?>
    <header class="page-head"><p class="eyebrow">EXAMS</p><h1>Exams &amp; grade scale</h1></header>
    <section class="grid-2">
      <div class="panel"><h2>Exams</h2><?php render_table(['#' => 'id', 'Exam' => 'name', 'Class' => 'class_name', 'Date' => 'exam_date'], $exams); ?></div>
      <div class="panel"><h2>Grades</h2><?php render_table(['Grade' => 'name', 'Min' => 'min_mark', 'Max' => 'max_mark', 'Comment' => 'comment'], $grades); ?></div>
    </section>

<?php /* ================= PAGE : EXAM MARKS ================= */
elseif ($page === 'marks'):
    $rows = all($pdo, "SELECT CONCAT(s.first_name,' ',s.last_name) AS student, c.name AS class_name, sub.name AS subject, m.mark,
                              (SELECT g.name FROM grades g WHERE m.mark BETWEEN g.min_mark AND g.max_mark LIMIT 1) AS grade
                       FROM exam_marks m
                       JOIN students s ON s.id=m.student_id
                       JOIN classes  c ON c.id=s.class_id
                       JOIN subjects sub ON sub.id=m.subject_id
                       ORDER BY s.id, sub.name LIMIT 120");
    $avg = all($pdo, "SELECT CONCAT(s.first_name,' ',s.last_name) AS student, ROUND(AVG(m.mark),2) AS average
                      FROM exam_marks m JOIN students s ON s.id=m.student_id GROUP BY s.id ORDER BY average DESC LIMIT 5");
?>
    <header class="page-head"><p class="eyebrow">RESULTS</p><h1>Exam marks</h1></header>
    <section class="grid-2">
      <div class="panel"><h2>Top 5 moyennes</h2><?php render_table(['Student' => 'student', 'Average' => 'average'], $avg); ?></div>
      <div class="panel"><h2>Toutes les notes (120 premieres)</h2><?php render_table(['Student' => 'student', 'Class' => 'class_name', 'Subject' => 'subject', 'Mark' => 'mark', 'Grade' => 'grade'], $rows); ?></div>
    </section>

<?php /* ================= PAGE : ATTENDANCE ================= */
elseif ($page === 'attendance'):
    $date = $_GET['date'] ?? one($pdo, "SELECT MAX(att_date) FROM attendance");
    $rows = all($pdo, "SELECT CONCAT(s.first_name,' ',s.last_name) AS student, c.name AS class_name, a.status
                       FROM attendance a JOIN students s ON s.id=a.student_id JOIN classes c ON c.id=a.class_id
                       WHERE a.att_date = ? ORDER BY c.id, s.last_name", [$date]);
?>
    <header class="page-head"><p class="eyebrow">ATTENDANCE</p><h1>Presences du <?= e($date) ?></h1>
      <form method="get" class="filters"><input type="hidden" name="page" value="attendance"><input type="date" name="date" value="<?= e($date) ?>"><button class="pill">Voir</button></form></header>
    <section class="panel"><?php render_table(['Student' => 'student', 'Class' => 'class_name', 'Status' => 'status'], $rows); ?></section>

<?php /* ================= PAGE : ACCOUNTING ================= */
elseif ($page === 'accounting'):
    $rows = all($pdo, "SELECT entry_date, type, category, description, amount FROM accounting ORDER BY entry_date DESC");
    $inv  = all($pdo, "SELECT CONCAT(s.first_name,' ',s.last_name) AS student, i.title, i.amount, i.due_date, i.status
                       FROM invoices i JOIN students s ON s.id=i.student_id ORDER BY i.status, i.due_date LIMIT 30");
?>
    <header class="page-head"><p class="eyebrow">FINANCE</p><h1>Accounting - income &amp; expenses</h1></header>
    <section class="panel"><h2>Journal</h2><?php render_table(['Date' => 'entry_date', 'Type' => 'type', 'Category' => 'category', 'Description' => 'description', 'Amount' => 'amount'], $rows); ?></section>
    <section class="panel"><h2>Invoices</h2><?php render_table(['Student' => 'student', 'Title' => 'title', 'Amount' => 'amount', 'Due' => 'due_date', 'Status' => 'status'], $inv); ?></section>

<?php /* ================= PAGE : EVENTS ================= */
elseif ($page === 'events'):
    $rows = all($pdo, "SELECT title, description, event_date, location FROM events ORDER BY event_date");
?>
    <header class="page-head"><p class="eyebrow">SCHOOL LIFE</p><h1>School events</h1></header>
    <section class="panel"><?php render_table(['Event' => 'title', 'Description' => 'description', 'Date' => 'event_date', 'Place' => 'location'], $rows); ?></section>

<?php /* ================= PAGE : LIBRARY ================= */
elseif ($page === 'library'):
    $books  = all($pdo, "SELECT title, author, quantity FROM books ORDER BY title");
    $issues = all($pdo, "SELECT b.title, CONCAT(s.first_name,' ',s.last_name) AS student, bi.issue_date, bi.return_date
                         FROM book_issues bi JOIN books b ON b.id=bi.book_id JOIN students s ON s.id=bi.student_id ORDER BY bi.issue_date DESC");
?>
    <header class="page-head"><p class="eyebrow">LIBRARY</p><h1>Books &amp; loans</h1></header>
    <section class="grid-2">
      <div class="panel"><h2>Books</h2><?php render_table(['Title' => 'title', 'Author' => 'author', 'Qty' => 'quantity'], $books); ?></div>
      <div class="panel"><h2>Loans</h2><?php render_table(['Book' => 'title', 'Student' => 'student', 'Issued' => 'issue_date', 'Returned' => 'return_date'], $issues); ?></div>
    </section>

<?php /* ================= PAGE : DORMITORY ================= */
elseif ($page === 'dormitory'):
    $rows = all($pdo, "SELECT d.name, d.capacity, COUNT(s.id) AS occupied FROM dormitories d LEFT JOIN students s ON s.dormitory_id=d.id GROUP BY d.id");
?>
    <header class="page-head"><p class="eyebrow">CAMPUS</p><h1>Dormitories</h1></header>
    <section class="panel"><?php render_table(['Dormitory' => 'name', 'Capacity' => 'capacity', 'Occupied' => 'occupied'], $rows); ?></section>

<?php /* ================= PAGE : TRANSPORT ================= */
elseif ($page === 'transport'):
    $rows = all($pdo, "SELECT r.name, r.vehicle, r.driver, r.fare, COUNT(s.id) AS riders FROM transport_routes r LEFT JOIN students s ON s.transport_id=r.id GROUP BY r.id");
?>
    <header class="page-head"><p class="eyebrow">CAMPUS</p><h1>Transport routes</h1></header>
    <section class="panel"><?php render_table(['Route' => 'name', 'Vehicle' => 'vehicle', 'Driver' => 'driver', 'Fare' => 'fare', 'Students' => 'riders'], $rows); ?></section>

<?php /* ================= PAGE : MESSAGES ================= */
elseif ($page === 'messages'):
    $rows = all($pdo, "SELECT us.full_name AS sender, ur.full_name AS receiver, m.subject, m.body, m.sent_at
                       FROM messages m JOIN users us ON us.id=m.sender_id JOIN users ur ON ur.id=m.receiver_id ORDER BY m.sent_at DESC");
?>
    <header class="page-head"><p class="eyebrow">COMMUNICATION</p><h1>Messages between users</h1></header>
    <section class="panel"><?php render_table(['From' => 'sender', 'To' => 'receiver', 'Subject' => 'subject', 'Message' => 'body', 'Sent' => 'sent_at'], $rows); ?></section>

<?php /* ================= PAGE : SETTINGS ================= */
elseif ($page === 'settings'):
    $rows = all($pdo, "SELECT setting_key, setting_value FROM settings ORDER BY setting_key");
?>
    <header class="page-head"><p class="eyebrow">SYSTEM</p><h1>System settings (general, sms, language)</h1></header>
    <section class="panel"><?php render_table(['Key' => 'setting_key', 'Value' => 'setting_value'], $rows); ?></section>

<?php endif; ?>
  </main>
</div>
</body>
</html>
