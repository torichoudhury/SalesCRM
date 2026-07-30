from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Q, Count
from django_filters.rest_framework import DjangoFilterBackend

from .models import (
    Task, TaskList, TaskMember, TaskAttachment, TaskNote,
    TaskCheckList, TaskLabel, Label, TaskPriority,
    TaskHierarchy, TaskStatusUpdate, TaskRejectComment,
    TaskReminder, TaskPlanner, Project, ProjectStatus,
    ProjectStatusUpdate, ProjectMember, ProjectComment,
    BookmarkProject, TrackTask, TrackProject,
    WorksheetLog, WorkGroup, WorkGroupProject,
)
from .serializers import (
    TaskListSerializer, TaskDetailSerializer,
    TaskListInProjectSerializer, TaskMemberSerializer, TaskAttachmentSerializer,
    TaskNoteSerializer, TaskCheckListSerializer, TaskLabelSerializer,
    TaskPrioritySerializer, LabelSerializer, TaskStatusUpdateSerializer,
    TaskReminderSerializer, TaskPlannerSerializer,
    ProjectListSerializer, ProjectDetailSerializer,
    ProjectStatusSerializer, ProjectMemberSerializer, ProjectCommentSerializer,
    ProjectStatusUpdateSerializer, WorkGroupSerializer,
    WorksheetLogSerializer, TaskDashboardSerializer,
)
from .permissions import IsTaskOwnerOrMember, IsProjectOwnerOrMember


# ─── TASK PRIORITY ────────────────────────────────────────────────────────────

class TaskPriorityViewSet(viewsets.ModelViewSet):
    queryset = TaskPriority.objects.all()
    serializer_class = TaskPrioritySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'code']


# ─── LABEL ────────────────────────────────────────────────────────────────────

class LabelViewSet(viewsets.ModelViewSet):
    serializer_class = LabelSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

    def get_queryset(self):
        return Label.objects.filter(
            Q(created_by=self.request.user) | Q(created_by__isnull=True)
        )

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


# ─── PROJECT STATUS ───────────────────────────────────────────────────────────

class ProjectStatusViewSet(viewsets.ModelViewSet):
    queryset = ProjectStatus.objects.all()
    serializer_class = ProjectStatusSerializer
    permission_classes = [IsAuthenticated]


# ─── PROJECT ──────────────────────────────────────────────────────────────────

class ProjectViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsProjectOwnerOrMember]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description']
    ordering_fields = ['created_on', 'end_date', 'title']
    ordering = ['-created_on']

    def get_queryset(self):
        user = self.request.user
        return Project.objects.filter(
            Q(created_by=user) | Q(members__user=user) | Q(assignee=user)
        ).filter(is_deleted=False).distinct().select_related('status', 'created_by', 'assignee')

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProjectDetailSerializer
        return ProjectListSerializer

    def perform_destroy(self, instance):
        instance.is_deleted = True
        instance.save()

    @action(detail=True, methods=['get'])
    def task_lists(self, request, pk=None):
        project = self.get_object()
        lists = project.task_lists.all()
        return Response(TaskListInProjectSerializer(lists, many=True).data)

    @action(detail=True, methods=['get'])
    def members(self, request, pk=None):
        project = self.get_object()
        members = project.members.select_related('user')
        return Response(ProjectMemberSerializer(members, many=True).data)

    @action(detail=True, methods=['post'])
    def add_member(self, request, pk=None):
        project = self.get_object()
        serializer = ProjectMemberSerializer(data={**request.data, 'project': project.id},
                                             context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=201)

    @action(detail=True, methods=['get'])
    def summary(self, request, pk=None):
        project = self.get_object()
        tasks = project.tasks.all()
        total = tasks.count()
        completed = tasks.filter(status='C').count()
        return Response({
            'total_tasks': total,
            'completed': completed,
            'open': tasks.filter(status='O').count(),
            'in_progress': tasks.filter(status='P').count(),
            'on_hold': tasks.filter(status='H').count(),
            'progress_pct': round((completed / total) * 100) if total else 0,
        })

    @action(detail=True, methods=['post'])
    def bookmark(self, request, pk=None):
        project = self.get_object()
        bm, created = BookmarkProject.objects.get_or_create(user=request.user, project=project)
        if not created:
            bm.delete()
            return Response({'bookmarked': False})
        return Response({'bookmarked': True}, status=201)

    @action(detail=False, methods=['get'])
    def bookmarked(self, request):
        bookmarked_ids = BookmarkProject.objects.filter(
            user=request.user
        ).values_list('project_id', flat=True)
        projects = Project.objects.filter(id__in=bookmarked_ids, is_deleted=False)
        return Response(ProjectListSerializer(projects, many=True, context={'request': request}).data)


# ─── TASK LIST ────────────────────────────────────────────────────────────────

class TaskListViewSet(viewsets.ModelViewSet):
    serializer_class = TaskListInProjectSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['project']

    def get_queryset(self):
        user = self.request.user
        return TaskList.objects.filter(
            Q(project__created_by=user) | Q(project__members__user=user)
        ).distinct()


# ─── TASK ─────────────────────────────────────────────────────────────────────

class TaskViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsTaskOwnerOrMember]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'task_type', 'project', 'task_list', 'assignee', 'assessment_status']
    search_fields = ['title', 'description', 'ticket_id', 'external_ref']
    ordering_fields = ['created_on', 'end_date', 'start_date', 'status']
    ordering = ['-created_on']

    def get_queryset(self):
        user = self.request.user
        return Task.objects.filter(
            Q(created_by=user) | Q(assignee=user) | Q(members__user=user)
        ).distinct().select_related('priority', 'assignee', 'created_by', 'project', 'task_list')

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return TaskDetailSerializer
        return TaskListSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    # ── Custom actions ────────────────────────────────────────────────────────

    @action(detail=False, methods=['get'])
    def my_tasks(self, request):
        """Tasks assigned to me or created by me."""
        tasks = Task.objects.filter(
            Q(assignee=request.user) | Q(created_by=request.user)
        ).exclude(status='C').select_related('priority', 'project')
        serializer = TaskListSerializer(tasks, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def overdue(self, request):
        """Tasks that are past their end_date and not complete."""
        today = timezone.now().date()
        tasks = self.get_queryset().filter(
            end_date__lt=today
        ).exclude(status__in=['C', 'H'])
        return Response(TaskListSerializer(tasks, many=True, context={'request': request}).data)

    @action(detail=False, methods=['get'])
    def kanban(self, request):
        """Tasks grouped by status for a kanban board."""
        project_id = request.query_params.get('project')
        qs = self.get_queryset()
        if project_id:
            qs = qs.filter(project_id=project_id)
        result = {}
        for code, label in Task.STATUS_CHOICES:
            result[code] = {
                'label': label,
                'tasks': TaskListSerializer(
                    qs.filter(status=code), many=True, context={'request': request}
                ).data
            }
        return Response(result)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Quickly change task status and log a status update."""
        task = self.get_object()
        new_status = request.data.get('status')
        valid = [s[0] for s in Task.STATUS_CHOICES]
        if new_status not in valid:
            return Response({'error': f'Invalid status. Valid: {valid}'}, status=400)
        # Capture the old display label BEFORE overwriting status
        old_status_display = task.get_status_display()
        task.status = new_status
        if new_status == 'C':
            task.completed_on = timezone.now()
            task.completed_percentage = 100
        task.save()
        new_status_display = dict(Task.STATUS_CHOICES)[new_status]
        TaskStatusUpdate.objects.create(
            task=task,
            status=new_status,
            description=f"Status changed from {old_status_display} → {new_status_display}",
            created_by=request.user,
        )
        return Response(TaskListSerializer(task, context={'request': request}).data)


    @action(detail=True, methods=['post'])
    def add_subtask(self, request, pk=None):
        """Link an existing task as a subtask, or create a new one."""
        parent = self.get_object()
        child_id = request.data.get('child_id')
        if child_id:
            child = Task.objects.get(id=child_id)
        else:
            data = {**request.data, 'project': parent.project_id}
            s = TaskListSerializer(data=data, context={'request': request})
            s.is_valid(raise_exception=True)
            child = s.save(created_by=request.user)
        TaskHierarchy.objects.get_or_create(parent=parent, child=child)
        return Response(TaskDetailSerializer(parent, context={'request': request}).data, status=201)

    @action(detail=True, methods=['post'])
    def log_time(self, request, pk=None):
        """Log time worked on this task."""
        task = self.get_object()
        s = WorksheetLogSerializer(
            data={**request.data, 'task': task.id}, context={'request': request}
        )
        s.is_valid(raise_exception=True)
        s.save(user=request.user, task=task)
        return Response(s.data, status=201)

    @action(detail=True, methods=['get'])
    def time_logs(self, request, pk=None):
        task = self.get_object()
        logs = task.time_logs.select_related('user')
        return Response(WorksheetLogSerializer(logs, many=True).data)

    @action(detail=True, methods=['get', 'post'])
    def checklist(self, request, pk=None):
        task = self.get_object()
        if request.method == 'GET':
            return Response(TaskCheckListSerializer(task.checklist.all(), many=True).data)
        s = TaskCheckListSerializer(data={**request.data, 'task': task.id}, context={'request': request})
        s.is_valid(raise_exception=True)
        s.save(created_by=request.user)
        return Response(s.data, status=201)

    @action(detail=True, methods=['get', 'post'])
    def notes(self, request, pk=None):
        task = self.get_object()
        if request.method == 'GET':
            return Response(TaskNoteSerializer(
                task.notes.select_related('created_by'), many=True
            ).data)
        s = TaskNoteSerializer(data={**request.data, 'task': task.id}, context={'request': request})
        s.is_valid(raise_exception=True)
        s.save(created_by=request.user)
        return Response(s.data, status=201)

    @action(detail=True, methods=['get', 'post'])
    def members(self, request, pk=None):
        task = self.get_object()
        if request.method == 'GET':
            return Response(TaskMemberSerializer(task.members.all(), many=True).data)
        s = TaskMemberSerializer(data={**request.data, 'task': task.id}, context={'request': request})
        s.is_valid(raise_exception=True)
        s.save()
        return Response(s.data, status=201)


# ─── TASK NOTE ────────────────────────────────────────────────────────────────

class TaskNoteViewSet(viewsets.ModelViewSet):
    serializer_class = TaskNoteSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['task']

    def get_queryset(self):
        user = self.request.user
        return TaskNote.objects.filter(
            Q(task__created_by=user) | Q(task__assignee=user) | Q(task__members__user=user)
        ).distinct().select_related('created_by', 'task')

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


# ─── TASK ATTACHMENT ──────────────────────────────────────────────────────────

class TaskAttachmentViewSet(viewsets.ModelViewSet):
    serializer_class = TaskAttachmentSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['task']

    def get_queryset(self):
        user = self.request.user
        return TaskAttachment.objects.filter(
            Q(task__created_by=user) | Q(task__assignee=user) | Q(task__members__user=user)
        ).distinct()

    def perform_create(self, serializer):
        serializer.save(uploaded_by=self.request.user)


# ─── CHECKLIST (standalone) ───────────────────────────────────────────────────

class TaskCheckListViewSet(viewsets.ModelViewSet):
    serializer_class = TaskCheckListSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['task', 'is_completed']

    def get_queryset(self):
        user = self.request.user
        return TaskCheckList.objects.filter(
            Q(task__created_by=user) | Q(task__assignee=user) | Q(task__members__user=user)
        ).distinct()

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


# ─── WORKSHEET LOG ────────────────────────────────────────────────────────────

class WorksheetLogViewSet(viewsets.ModelViewSet):
    serializer_class = WorksheetLogSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['task']
    ordering = ['-logged_on']

    def get_queryset(self):
        return WorksheetLog.objects.filter(user=self.request.user).select_related('task')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# ─── WORK GROUP ───────────────────────────────────────────────────────────────

class WorkGroupViewSet(viewsets.ModelViewSet):
    serializer_class = WorkGroupSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

    def get_queryset(self):
        return WorkGroup.objects.filter(created_by=self.request.user)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def add_project(self, request, pk=None):
        wg = self.get_object()
        project_id = request.data.get('project')
        try:
            project = Project.objects.get(id=project_id)
        except Project.DoesNotExist:
            return Response({'error': 'Project not found'}, status=404)
        WorkGroupProject.objects.get_or_create(work_group=wg, project=project)
        return Response({'status': 'added'}, status=201)


# ─── TASK DASHBOARD ───────────────────────────────────────────────────────────

class TaskDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        today = timezone.now().date()

        user_tasks = Task.objects.filter(
            Q(created_by=user) | Q(assignee=user) | Q(members__user=user)
        ).distinct()

        my_tasks_qs = Task.objects.filter(
            Q(assignee=user) | Q(created_by=user)
        ).distinct()

        overdue = user_tasks.filter(
            end_date__lt=today
        ).exclude(status__in=['C', 'H']).count()

        user_projects = Project.objects.filter(
            Q(created_by=user) | Q(members__user=user) | Q(assignee=user)
        ).filter(is_deleted=False).distinct()

        data = {
            'total_tasks': user_tasks.count(),
            'open_tasks': user_tasks.filter(status='O').count(),
            'in_progress': user_tasks.filter(status='P').count(),
            'on_hold': user_tasks.filter(status='H').count(),
            'completed': user_tasks.filter(status='C').count(),
            'overdue': overdue,
            'my_tasks': my_tasks_qs.exclude(status='C').count(),
            'total_projects': user_projects.count(),
            'active_projects': user_projects.filter(
                extended_status__isnull=True, is_deleted=False
            ).count(),
        }
        return Response(TaskDashboardSerializer(data).data)
