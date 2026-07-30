from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth.models import User

class DashboardTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_superuser(
            username='testuser', password='testpass123', email='test@example.com'
        )
        self.client.force_authenticate(user=self.user)

    def test_dashboard_summary(self):
        response = self.client.get('/api/dashboard/summary/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test for the correct metrics
        data = response.data
        self.assertIn('sales_metrics', data)
        self.assertIn('quote_metrics', data)
        self.assertNotIn('inventory_status', data)
        self.assertNotIn('reservations', data)
