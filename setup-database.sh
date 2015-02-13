#!/bin/sh

mysql -u root -e "DROP USER 'test'@'localhost';" || true
mysql -u root -e "FLUSH PRIVILEGES; CREATE USER 'test'@'localhost'; GRANT ALL PRIVILEGES ON *.* TO 'test'@'localhost' WITH GRANT OPTION;"