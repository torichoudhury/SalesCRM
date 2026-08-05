import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_core.settings')
django.setup()

from django.db import connection
from django.core.management import call_command

def main():
    print("=== Step 1: Cleaning Database ===")
    with connection.cursor() as cursor:
        if connection.vendor == 'postgresql':
            print("PostgreSQL detected: Dropping and recreating public schema for clean import...")
            cursor.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")
        elif connection.vendor == 'mysql':
            print("MySQL detected: Dropping all tables...")
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
            cursor.execute("SHOW TABLES;")
            tables = [t[0] for t in cursor.fetchall()]
            for t in tables:
                cursor.execute(f"DROP TABLE IF EXISTS `{t}`;")
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")

    print("=== Step 2: Running Django migrations ===")
    call_command('migrate', interactive=False)

    print("=== Step 3: Loading data fixture (datadump.json) ===")
    call_command('loaddata', 'datadump.json')
    print("=== Database Reset & Import Completed Successfully! ===")

if __name__ == '__main__':
    main()
