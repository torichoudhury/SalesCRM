from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APITestCase
from crm.models import Customer, Opportunity, Quote

class CRMTests(APITestCase):
    def setUp(self):
        # Create and authenticate a user so all protected endpoints return 200/201
        self.user = User.objects.create_superuser(
            username='testuser', password='testpass123', email='test@example.com'
        )
        self.client.force_authenticate(user=self.user)

        self.customer = Customer.objects.create(name="Test Customer", email="test@example.com")
        self.opportunity = Opportunity.objects.create(
            title="Test Opp", 
            customer=self.customer,
            expected_revenue=10000,
            stage="New"
        )
        self.quote = Quote.objects.create(
            customer=self.customer,
            opportunity=self.opportunity,
            total=9000,
            status="Draft"
        )

    def test_customer_list(self):
        response = self.client.get('/api/crm/customers/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_opportunity_kanban(self):
        response = self.client.get('/api/crm/opportunities/kanban/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('New', response.data)
        self.assertEqual(len(response.data['New']), 1)
        self.assertEqual(response.data['New'][0]['title'], "Test Opp")

    def test_convert_to_sales_order(self):
        url = f'/api/crm/quotes/{self.quote.id}/convert_to_sales_order/'
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['total'], "9000.00")
        
        # Test converting again should fail
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

