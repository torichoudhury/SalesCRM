from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    TaskViewSet, TaskListViewSet, TaskNoteViewSet, TaskAttachmentViewSet,
    TaskCheckListViewSet, LabelViewSet, TaskPriorityViewSet,
    ProjectViewSet, ProjectStatusViewSet, WorkGroupViewSet,
    WorksheetLogViewSet, TaskDashboardView,
)

router = DefaultRouter()
router.register(r'tasks',          TaskViewSet,          basename='task')
router.register(r'task-lists',     TaskListViewSet,      basename='task-list')
router.register(r'task-notes',     TaskNoteViewSet,      basename='task-note')
router.register(r'task-attachments', TaskAttachmentViewSet, basename='task-attachment')
router.register(r'task-checklist', TaskCheckListViewSet, basename='task-checklist')
router.register(r'labels',         LabelViewSet,         basename='label')
router.register(r'task-priorities', TaskPriorityViewSet, basename='task-priority')
router.register(r'projects',       ProjectViewSet,       basename='project')
router.register(r'project-statuses', ProjectStatusViewSet, basename='project-status')
router.register(r'work-groups',    WorkGroupViewSet,     basename='work-group')
router.register(r'time-logs',      WorksheetLogViewSet,  basename='time-log')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', TaskDashboardView.as_view(), name='task-dashboard'),
]
