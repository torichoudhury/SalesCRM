from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CustomerViewSet, ContactViewSet, OpportunityViewSet,
    QuoteViewSet, QuoteLineItemViewSet, SalesOrderViewSet,
    InvoiceViewSet, LogNoteViewSet
)

router = DefaultRouter()
router.register(r'customers', CustomerViewSet)
router.register(r'contacts', ContactViewSet)
router.register(r'opportunities', OpportunityViewSet)
router.register(r'quotes', QuoteViewSet)
router.register(r'quote-line-items', QuoteLineItemViewSet)
router.register(r'sales-orders', SalesOrderViewSet)
router.register(r'invoices', InvoiceViewSet)
router.register(r'log-notes', LogNoteViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
