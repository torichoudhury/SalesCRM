from django.db import models
from django.utils import timezone


class Customer(models.Model):
    TYPE_CHOICES = (
        ('Company', 'Company'),
        ('Individual', 'Individual'),
    )
    PAYMENT_TERMS_CHOICES = (
        ('COD', 'Cash on Delivery'),
        ('7 Days', '7 Days'),
        ('15 Days', '15 Days'),
        ('30 Days', '30 Days'),
        ('45 Days', '45 Days'),
        ('60 Days', '60 Days'),
        ('90 Days', '90 Days'),
    )

    name = models.CharField(max_length=255)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='Company')
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=50, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)
    country = models.CharField(max_length=100, blank=True, null=True, default='Malaysia')
    zipcode = models.CharField(max_length=20, blank=True, null=True)
    payment_terms = models.CharField(max_length=20, choices=PAYMENT_TERMS_CHOICES, blank=True, null=True)
    tax_id = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Contact(models.Model):
    DESIGNATION_CHOICES = (
        ('Main', 'Main'),
        ('Finance', 'Finance'),
        ('Management', 'Management'),
        ('Operations', 'Operations'),
        ('Other', 'Other'),
    )

    customer = models.ForeignKey(Customer, related_name='contacts', on_delete=models.CASCADE)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=50, blank=True, null=True)
    designation = models.CharField(max_length=20, choices=DESIGNATION_CHOICES, default='Main')
    address = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)
    country = models.CharField(max_length=100, blank=True, null=True, default='Malaysia')
    zipcode = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name or ''}".strip()


class Opportunity(models.Model):
    STAGE_CHOICES = (
        ('New', 'New'),
        ('Qualified', 'Qualified'),
        ('Negotiation', 'Negotiation'),
        ('Won', 'Won'),
        ('Closed', 'Closed'),
        ('Lost', 'Lost'),
    )
    PRIORITY_CHOICES = (
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
    )
    CATEGORY_CHOICES = (
        ('New Business', 'New Business'),
        ('Existing Business', 'Existing Business'),
        ('Renewal', 'Renewal'),
        ('Upsell', 'Upsell'),
        ('Other', 'Other'),
    )
    REFERRAL_CHOICES = (
        ('Website', 'Website'),
        ('Referral', 'Referral'),
        ('Cold Call', 'Cold Call'),
        ('Social Media', 'Social Media'),
        ('Event', 'Event'),
        ('Walk-in', 'Walk-in'),
        ('Other', 'Other'),
    )

    number = models.CharField(max_length=20, unique=True, blank=True)
    title = models.CharField(max_length=255)
    customer = models.ForeignKey(Customer, related_name='opportunities', on_delete=models.CASCADE)
    contact = models.ForeignKey(Contact, related_name='opportunities', on_delete=models.SET_NULL, blank=True, null=True)
    expected_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    expected_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    stage = models.CharField(max_length=20, choices=STAGE_CHOICES, default='New')
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='Medium')
    category = models.CharField(max_length=30, choices=CATEGORY_CHOICES, blank=True, null=True)
    referral_source = models.CharField(max_length=30, choices=REFERRAL_CHOICES, blank=True, null=True)
    sales_rep = models.CharField(max_length=255, blank=True, null=True)
    tags = models.CharField(max_length=500, blank=True, null=True)
    remark = models.TextField(blank=True, null=True)
    expected_closing_date = models.DateField(blank=True, null=True)
    win_prediction = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.number:
            self.number = f"OP-CRM-{self.id:05d}"
            Opportunity.objects.filter(pk=self.pk).update(number=self.number)

    def __str__(self):
        return f"{self.number} - {self.title}"


class Quote(models.Model):
    STATUS_CHOICES = (
        ('Draft', 'Draft'),
        ('Sent', 'Sent'),
        ('Approved', 'Approved'),
        ('Rejected', 'Rejected'),
        ('Expired', 'Expired'),
    )

    number = models.CharField(max_length=20, unique=True, blank=True)
    opportunity = models.ForeignKey(Opportunity, on_delete=models.CASCADE, related_name='quotes', blank=True, null=True)
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='quotes')
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Draft')
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    charges = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    remark = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.number:
            self.number = f"QT-CRM-{self.id:05d}"
            Quote.objects.filter(pk=self.pk).update(number=self.number)

    def __str__(self):
        return self.number


class QuoteLineItem(models.Model):
    quote = models.ForeignKey(Quote, related_name='line_items', on_delete=models.CASCADE)
    product = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    pax = models.IntegerField(default=1)
    discount = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    tax = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    def save(self, *args, **kwargs):
        from decimal import Decimal
        pax_dec = Decimal(str(self.pax))
        price_dec = Decimal(str(self.unit_price))
        discount_dec = Decimal(str(self.discount))
        tax_dec = Decimal(str(self.tax))
        
        discounted = price_dec * pax_dec * (Decimal('1') - discount_dec / Decimal('100'))
        self.total = (discounted * (Decimal('1') + tax_dec / Decimal('100'))).quantize(Decimal('0.01'))
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.quote.number} - {self.product}"


class SalesOrder(models.Model):
    STATUS_CHOICES = (
        ('Draft', 'Draft'),
        ('Confirmed', 'Confirmed'),
        ('Delivered', 'Delivered'),
        ('Cancelled', 'Cancelled'),
    )

    number = models.CharField(max_length=20, unique=True, blank=True)
    quote = models.OneToOneField(Quote, on_delete=models.CASCADE, related_name='sales_order', blank=True, null=True)
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='sales_orders')
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Draft')
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    remark = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.number:
            self.number = f"SO-CRM-{self.id:05d}"
            SalesOrder.objects.filter(pk=self.pk).update(number=self.number)

    def __str__(self):
        return self.number


class Invoice(models.Model):
    STATUS_CHOICES = (
        ('Draft', 'Draft'),
        ('Sent', 'Sent'),
        ('Paid', 'Paid'),
        ('Overdue', 'Overdue'),
        ('Cancelled', 'Cancelled'),
    )

    number = models.CharField(max_length=20, unique=True, blank=True)
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='invoices')
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, blank=True, null=True)
    date_issued = models.DateField(default=timezone.now)
    due_date = models.DateField(blank=True, null=True)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Draft')
    remark = models.TextField(blank=True, null=True)
    memo = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.number:
            self.number = f"INV-CRM-{self.id:05d}"
            Invoice.objects.filter(pk=self.pk).update(number=self.number)

    def __str__(self):
        return self.number


class LogNote(models.Model):
    TYPE_CHOICES = (
        ('Note', 'Note'),
        ('Call', 'Call'),
        ('Meeting', 'Meeting'),
        ('Email', 'Email'),
        ('Task', 'Task'),
    )

    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='log_notes', blank=True, null=True)
    opportunity = models.ForeignKey(Opportunity, on_delete=models.CASCADE, related_name='log_notes', blank=True, null=True)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='Note')
    note = models.TextField()
    created_by = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.type} - {self.created_at.strftime('%Y-%m-%d')}"

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

@receiver([post_save, post_delete], sender=QuoteLineItem)
def sync_quote_total(sender, instance, **kwargs):
    if kwargs.get('raw'):
        return
    from decimal import Decimal
    quote = instance.quote
    items = quote.line_items.all()
    subtotal = sum(Decimal(str(i.unit_price)) * Decimal(str(i.pax)) * (Decimal('1') - Decimal(str(i.discount)) / Decimal('100')) for i in items)
    tax = sum((Decimal(str(i.unit_price)) * Decimal(str(i.pax)) * (Decimal('1') - Decimal(str(i.discount)) / Decimal('100'))) * (Decimal(str(i.tax)) / Decimal('100')) for i in items)
    
    quote.subtotal = subtotal.quantize(Decimal('0.01'))
    quote.tax = tax.quantize(Decimal('0.01'))
    quote.total = (quote.subtotal + quote.tax - Decimal(str(quote.discount)) + Decimal(str(quote.charges))).quantize(Decimal('0.01'))
    quote.save(update_fields=['subtotal', 'tax', 'total'])

@receiver(post_save, sender=Quote)
def auto_create_sales_order(sender, instance, created, **kwargs):
    if kwargs.get('raw'):
        return
    if instance.status == 'Approved':
        if not hasattr(instance, 'sales_order'):
            SalesOrder.objects.create(
                quote=instance,
                customer=instance.customer,
                contact=instance.contact,
                total=instance.total,
                status='Confirmed',
            )

