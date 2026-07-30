from rest_framework import serializers
from .models import (
    Customer, Contact, Opportunity, Quote, QuoteLineItem,
    SalesOrder, Invoice, LogNote
)


class ContactSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = Contact
        fields = '__all__'

    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name or ''}".strip()


class CustomerSerializer(serializers.ModelSerializer):
    contacts_count = serializers.SerializerMethodField()
    opportunities_count = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = '__all__'

    def get_contacts_count(self, obj):
        return obj.contacts.count()

    def get_opportunities_count(self, obj):
        return obj.opportunities.count()


class CustomerDetailSerializer(serializers.ModelSerializer):
    contacts = ContactSerializer(many=True, read_only=True)
    contacts_count = serializers.SerializerMethodField()
    opportunities_count = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = '__all__'

    def get_contacts_count(self, obj):
        return obj.contacts.count()

    def get_opportunities_count(self, obj):
        return obj.opportunities.count()


class QuoteLineItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuoteLineItem
        fields = '__all__'


class OpportunitySerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    contact_name = serializers.SerializerMethodField()
    quotes_count = serializers.SerializerMethodField()

    class Meta:
        model = Opportunity
        fields = '__all__'

    def get_contact_name(self, obj):
        if obj.contact:
            return f"{obj.contact.first_name} {obj.contact.last_name or ''}".strip()
        return None

    def get_quotes_count(self, obj):
        return obj.quotes.count()


class QuoteSerializer(serializers.ModelSerializer):
    line_items = QuoteLineItemSerializer(many=True, read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    opportunity_title = serializers.SerializerMethodField()

    class Meta:
        model = Quote
        fields = '__all__'

    def get_opportunity_title(self, obj):
        return obj.opportunity.title if obj.opportunity else None


class SalesOrderSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    quote_number = serializers.SerializerMethodField()

    class Meta:
        model = SalesOrder
        fields = '__all__'

    def get_quote_number(self, obj):
        return obj.quote.number if obj.quote else None


class InvoiceSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.name', read_only=True)

    class Meta:
        model = Invoice
        fields = '__all__'


class LogNoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = LogNote
        fields = '__all__'
