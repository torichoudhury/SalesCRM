from django.test import TestCase, Client
from django.contrib.auth.models import User
from tasks.models import Project, Task, TaskPriority
from rest_framework_simplejwt.tokens import RefreshToken


class TasksAPITestCase(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(username='testuser', password='password123')
        refresh = RefreshToken.for_user(self.user)
        self.token = str(refresh.access_token)
        self.auth_headers = {'HTTP_AUTHORIZATION': f'Bearer {self.token}'}

    def test_create_project(self):
        data = {
            'title': 'Test Project',
            'description': 'Description here',
            'privacy': 'A'
        }
        response = self.client.post('/api/tasks/projects/', data, content_type='application/json', **self.auth_headers)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()['title'], 'Test Project')
        self.assertEqual(Project.objects.count(), 1)

    def test_create_task(self):
        project = Project.objects.create(title='P1', created_by=self.user)
        priority = TaskPriority.objects.create(name='High', code='H')
        data = {
            'title': 'Test Task',
            'project': project.id,
            'priority': priority.id
        }
        response = self.client.post('/api/tasks/tasks/', data, content_type='application/json', **self.auth_headers)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()['title'], 'Test Task')
        self.assertEqual(Task.objects.count(), 1)

    def test_dashboard_summary(self):
        response = self.client.get('/api/tasks/dashboard/', **self.auth_headers)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('total_tasks', data)
        self.assertIn('total_projects', data)
