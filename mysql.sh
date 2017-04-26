package: MySQL
version: "1.0"
system_requirement_missing: "Please install the MySQL/MariaDB development package."
system_requirement: ".*"
system_requirement_check: |
  printf "#include <mysql.h>\n" | cc -xc - `mysql_config --include` -c -o /dev/null
---
