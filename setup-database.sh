#!/bin/sh

mysql -u root -e "DROP USER 'test'@'localhost'; FLUSH PRIVILEGES; CREATE USER 'test'@'localhost'; GRANT ALL PRIVILEGES ON *.* TO 'test'@'localhost' WITH GRANT OPTION;"