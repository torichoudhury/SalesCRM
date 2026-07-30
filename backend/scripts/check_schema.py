import re
with open('../task_module_model_definitions.md', encoding='utf-8') as f:
    c = f.read()
tables = re.findall(r'db_table = "([^"]+)"', c)
cols = re.findall(r'db_column=.([^"\']+).', c)[:15]
print("Tables:", tables)
print("Sample cols:", cols)
