from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.http import HttpResponse
from reportlab.pdfgen import canvas
import io

from .models import (
    Customer, Contact, Opportunity, Quote, QuoteLineItem,
    SalesOrder, Invoice, LogNote
)
from .serializers import (
    CustomerSerializer, CustomerDetailSerializer, ContactSerializer,
    OpportunitySerializer, QuoteSerializer, QuoteLineItemSerializer,
    SalesOrderSerializer, InvoiceSerializer, LogNoteSerializer
)


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all().order_by('-created_at')
    serializer_class = CustomerSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'email', 'phone', 'city', 'country']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CustomerDetailSerializer
        return CustomerSerializer

    @action(detail=True, methods=['get'])
    def contacts(self, request, pk=None):
        customer = self.get_object()
        contacts = customer.contacts.all().order_by('-created_at')
        serializer = ContactSerializer(contacts, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def opportunities(self, request, pk=None):
        customer = self.get_object()
        opps = customer.opportunities.all().order_by('-created_at')
        serializer = OpportunitySerializer(opps, many=True)
        return Response(serializer.data)


class ContactViewSet(viewsets.ModelViewSet):
    queryset = Contact.objects.all().order_by('-created_at')
    serializer_class = ContactSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['first_name', 'last_name', 'email', 'phone', 'designation']


class OpportunityViewSet(viewsets.ModelViewSet):
    queryset = Opportunity.objects.all().order_by('-created_at')
    serializer_class = OpportunitySerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'number', 'stage', 'customer__name']

    @action(detail=False, methods=['get'])
    def kanban(self, request):
        """Return opportunities grouped by stage for kanban view."""
        stages = ['New', 'Qualified', 'Negotiation', 'Won', 'Closed', 'Lost']
        result = {}
        for stage in stages:
            opps = Opportunity.objects.filter(stage=stage).order_by('-created_at')
            result[stage] = OpportunitySerializer(opps, many=True).data
        return Response(result)


class QuoteViewSet(viewsets.ModelViewSet):
    queryset = Quote.objects.all().order_by('-created_at')
    serializer_class = QuoteSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['number', 'status', 'customer__name']

    @action(detail=True, methods=['post'])
    def convert_to_sales_order(self, request, pk=None):
        """Convert an approved quotation to a Sales Order."""
        quote = self.get_object()
        if hasattr(quote, 'sales_order'):
            return Response({'error': 'Sales order already exists for this quote.'}, status=400)
        so = SalesOrder.objects.create(
            quote=quote,
            customer=quote.customer,
            contact=quote.contact,
            total=quote.total,
            status='Confirmed',
        )
        return Response(SalesOrderSerializer(so).data, status=201)

    @action(detail=True, methods=['get'])
    def generate_pdf(self, request, pk=None):
        quote = self.get_object()
        buffer = io.BytesIO()
        p = canvas.Canvas(buffer)
        p.setFont("Helvetica-Bold", 16)
        p.drawString(100, 800, f"Quotation: {quote.number}")
        p.setFont("Helvetica", 12)
        p.drawString(100, 770, f"Customer: {quote.customer.name}")
        p.drawString(100, 750, f"Status: {quote.status}")
        p.drawString(100, 730, f"Total: MYR {quote.total}")
        p.drawString(100, 710, f"Date: {quote.created_at.strftime('%Y-%m-%d')}")
        p.showPage()
        p.save()
        buffer.seek(0)
        response = HttpResponse(buffer, content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="{quote.number}.pdf"'
        return response


class QuoteLineItemViewSet(viewsets.ModelViewSet):
    queryset = QuoteLineItem.objects.all()
    serializer_class = QuoteLineItemSerializer


class SalesOrderViewSet(viewsets.ModelViewSet):
    queryset = SalesOrder.objects.all().order_by('-created_at')
    serializer_class = SalesOrderSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['number', 'status', 'customer__name']


class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.all().order_by('-created_at')
    serializer_class = InvoiceSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['number', 'status', 'customer__name']

    @action(detail=False, methods=['get'])
    def ar_ageing(self, request):
        """Return AR ageing summary grouped by overdue bands."""
        from django.utils import timezone
        from decimal import Decimal
        today = timezone.now().date()
        invoices = Invoice.objects.exclude(status='Paid').exclude(status='Cancelled')
        bands = {'current': Decimal('0'), '1_30': Decimal('0'), '31_60': Decimal('0'), '61_90': Decimal('0'), 'over_90': Decimal('0')}
        for inv in invoices:
            if inv.due_date is None:
                bands['current'] += inv.total
                continue
            days = (today - inv.due_date).days
            if days <= 0:
                bands['current'] += inv.total
            elif days <= 30:
                bands['1_30'] += inv.total
            elif days <= 60:
                bands['31_60'] += inv.total
            elif days <= 90:
                bands['61_90'] += inv.total
            else:
                bands['over_90'] += inv.total
        return Response({k: str(v) for k, v in bands.items()})


class LogNoteViewSet(viewsets.ModelViewSet):
    queryset = LogNote.objects.all().order_by('-created_at')
    serializer_class = LogNoteSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['note', 'type']
