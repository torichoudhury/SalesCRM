import pymysql

try:
    connection = pymysql.connect(
        host='localhost',
        user='root',
        password='root',
        port=3306
    )
    with connection.cursor() as cursor:
        cursor.execute("CREATE DATABASE IF NOT EXISTS talxone_crm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
    connection.commit()
    print("Database talxone_crm created successfully.")
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'connection' in locals() and connection.open:
        connection.close()
