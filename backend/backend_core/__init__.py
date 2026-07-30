# PyMySQL fallback — used when mysqlclient C extension cannot be compiled on Windows.
try:
    import pymysql
    pymysql.install_as_MySQLdb()
except ImportError:
    pass

