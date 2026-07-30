from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from django.utils import timezone
from django.db.models import Sum
from django.db.models.functions import TruncMonth


class DashboardSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        from crm.models import Customer, Opportunity, Quote, SalesOrder, Invoice

        # ── Revenue (paid invoices) ─────────────────────────────────────────
        total_revenue = float(
            Invoice.objects.filter(status='Paid').aggregate(t=Sum('total'))['t'] or 0
        )

        # ── Outstanding Receivables ────────────
        total_outstanding = float(
            Invoice.objects.filter(status__in=['Sent', 'Overdue'])
            .aggregate(t=Sum('total'))['t'] or 0
        )
        outstanding_receivables = total_outstanding
        gross_profit = total_revenue

        # ── CRM counts ──────────────────────────────────────────────────────
        total_customers = Customer.objects.count()
        total_opportunities = Opportunity.objects.count()
        won_revenue = float(
            Opportunity.objects.filter(stage='Won')
            .aggregate(t=Sum('expected_revenue'))['t'] or 0
        )

        # ── Sales & Quotes ──────────────────────────────────────────────────
        total_sales_orders = SalesOrder.objects.count()
        pending_invoices_count = Invoice.objects.filter(
            status__in=['Sent', 'Overdue']
        ).count()
        active_quotes = Quote.objects.filter(status__in=['Draft', 'Sent']).count()

        # ── Budget proxy: target = total pipeline expected revenue ──────────
        budget_target = float(
            Opportunity.objects.aggregate(t=Sum('expected_revenue'))['t'] or 200000
        )
        if budget_target <= 0:
            budget_target = 200000.0
            
        achieved_percent = round(total_revenue / budget_target * 100, 1)

        # ── Revenue trend: monthly from paid invoices ───────────────────────
        revenue_by_month = (
            Invoice.objects.filter(status='Paid')
            .annotate(month=TruncMonth('date_issued'))
            .values('month')
            .annotate(revenue=Sum('total'))
            .order_by('month')
        )

        revenue_trends = [
            {
                'month': entry['month'].strftime('%b'),
                'revenue': float(entry['revenue'] or 0),
                'expenses': 0,
            }
            for entry in revenue_by_month
        ]

        # ── Pipeline breakdown by stage ─────────────────────────────────────
        stages = ['New', 'Qualified', 'Negotiation', 'Won', 'Closed', 'Lost']
        pipeline = {
            stage: {
                'count': Opportunity.objects.filter(stage=stage).count(),
                'value': float(
                    Opportunity.objects.filter(stage=stage)
                    .aggregate(t=Sum('expected_revenue'))['t'] or 0
                ),
            }
            for stage in stages
        }

        data = {
            # Flutter dashboard reads these exact keys
            'kpis': {
                'total_revenue': total_revenue,
                'outstanding_receivables': outstanding_receivables,
                'gross_profit': gross_profit,
                'won_revenue': won_revenue,
            },
            'crm_performance': {
                'customers': total_customers,
                'opportunities': total_opportunities,
            },
            'sales_metrics': {
                'sales_orders': total_sales_orders,
                'pending_invoices': pending_invoices_count,
            },
            'quote_metrics': {
                'active_quotes': active_quotes,
                'unpaid_amount': total_outstanding,
            },
            # Flutter _BudgetProgressCard requires this exact shape
            'budget': {
                'target': budget_target,
                'achieved_percent': achieved_percent,
            },
            'pipeline': pipeline,
            'revenue_trends': revenue_trends,
        }
        return Response(data)
