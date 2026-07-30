import django, os, sys
sys.path.insert(0, os.path.dirname(__file__))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend_core.settings')
django.setup()

from crm.models import Customer, Contact, Opportunity, Quote, SalesOrder, Invoice
from system_admin.models import Role, Subsidiary
from django.contrib.auth.models import User

SEP = "-" * 50

print(SEP)
print("SALES CRM")
print(SEP)
print(f"Customers:     {Customer.objects.count()}")
for c in Customer.objects.all():
    print(f"  [{c.id}] {c.name} ({c.type})")

print()
print(f"Contacts:      {Contact.objects.count()}")
for c in Contact.objects.all():
    print(f"  [{c.id}] {c.first_name} {c.last_name or ''} -> {c.customer.name}")

print()
print(f"Opportunities: {Opportunity.objects.count()}")
for o in Opportunity.objects.all():
    print(f"  [{o.id}] {o.number} | {o.title[:40]} | {o.stage}")

print()
print(f"Quotes:        {Quote.objects.count()}")
for q in Quote.objects.all():
    print(f"  [{q.id}] {q.number} | {q.status} | MYR {q.total}")

print()
print(f"Sales Orders:  {SalesOrder.objects.count()}")
for s in SalesOrder.objects.all():
    print(f"  [{s.id}] {s.number} | {s.status} | MYR {s.total}")

print()
print(SEP)
print("RECEIVABLES (Invoices)")
print(SEP)
print(f"Invoices: {Invoice.objects.count()}")
for inv in Invoice.objects.all():
    print(f"  [{inv.id}] {inv.number} | {inv.status} | MYR {inv.total} | Due={inv.due_date}")

print()
print(SEP)
print("ADMIN - Roles & Subsidiaries")
print(SEP)
print(f"Users: {User.objects.count()}")
for u in User.objects.all():
    print(f"  [{u.id}] {u.username} (staff={u.is_staff})")

print()
print(f"Roles: {Role.objects.count()}")
for r in Role.objects.all():
    print(f"  [{r.id}] {r.name}")

print()
print(f"Subsidiaries: {Subsidiary.objects.count()}")
for s in Subsidiary.objects.all():
    print(f"  [{s.id}] {s.name}")

print()
print(SEP)
print("All sections above are what the app fetches from the real DB.")
print(SEP)
