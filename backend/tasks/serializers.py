from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    Task, TaskList, TaskMember, TaskAttachment, TaskNote, TaskNoteAttachment,
    TaskNoteHierarchy, TaskCheckList, TaskLabel, Label, TaskPriority,
    TaskHierarchy, TaskStatusUpdate, TaskRejectComment, TaskReminder,
    TaskReminderMember, TaskPlanner, Project, ProjectStatus, ProjectStatusUpdate,
    ProjectMember, ProjectComment, ProjectCommentHierarchy, BookmarkProject,
    TrackTask, TrackProject, WorksheetLog, WorkGroup, WorkGroupProject,
    Subproject,
)


# ─── USER (minimal) ───────────────────────────────────────────────────────────

class UserBriefSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'full_name']

    def get_full_name(self, obj):
        return obj.get_full_name() or obj.username


# ─── PRIORITY & LABEL ─────────────────────────────────────────────────────────

class TaskPrioritySerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskPriority
        fields = ['id', 'name', 'code', 'color', 'order']


class LabelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Label
        fields = ['id', 'name', 'color']


# ─── TASK CHECKLIST ───────────────────────────────────────────────────────────

class TaskCheckListSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskCheckList
        fields = ['id', 'description', 'is_completed', 'task', 'created_by', 'created_on']
        read_only_fields = ['created_by', 'created_on']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


# ─── TASK MEMBER ──────────────────────────────────────────────────────────────

class TaskMemberSerializer(serializers.ModelSerializer):
    user_detail = UserBriefSerializer(source='user', read_only=True)

    class Meta:
        model = TaskMember
        fields = ['id', 'task', 'user', 'user_detail', 'type']


# ─── TASK ATTACHMENT ──────────────────────────────────────────────────────────

class TaskAttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskAttachment
        fields = ['id', 'title', 'description', 'file', 'task', 'uploaded_by', 'created_on']
        read_only_fields = ['uploaded_by', 'created_on']

    def create(self, validated_data):
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)


# ─── TASK NOTE ────────────────────────────────────────────────────────────────

class TaskNoteAttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskNoteAttachment
        fields = ['id', 'file', 'note', 'created_on']
        read_only_fields = ['created_on']


class TaskNoteSerializer(serializers.ModelSerializer):
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)
    attachments = TaskNoteAttachmentSerializer(many=True, read_only=True)

    class Meta:
        model = TaskNote
        fields = [
            'id', 'task', 'notes', 'created_by', 'created_by_detail',
            'attachments', 'is_auto_remove', 'remove_date', 'created_on', 'updated_on'
        ]
        read_only_fields = ['created_by', 'created_on', 'updated_on']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


# ─── TASK STATUS UPDATE ───────────────────────────────────────────────────────

class TaskStatusUpdateSerializer(serializers.ModelSerializer):
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)

    class Meta:
        model = TaskStatusUpdate
        fields = ['id', 'task', 'title', 'status', 'description',
                  'created_by', 'created_by_detail', 'created_on', 'last_modified']
        read_only_fields = ['created_by', 'created_on', 'last_modified']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


# ─── TASK REMINDER ────────────────────────────────────────────────────────────

class TaskReminderSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskReminder
        fields = [
            'id', 'name', 'task', 'reminder_type', 'day', 'hour', 'minute', 'time',
            'remind_assignee', 'remind_creator', 'remind_members', 'remind_custom_users', 'parent'
        ]


# ─── TASK PLANNER ─────────────────────────────────────────────────────────────

class TaskPlannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskPlanner
        fields = [
            'id', 'task', 'start_date', 'end_date', 'startdatetime', 'enddatetime',
            'remarks', 'status', 'created_by', 'created_on', 'last_modified'
        ]
        read_only_fields = ['created_by', 'created_on', 'last_modified']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


# ─── WORKSHEET LOG ────────────────────────────────────────────────────────────

class WorksheetLogSerializer(serializers.ModelSerializer):
    hours_logged = serializers.ReadOnlyField()
    user_detail = UserBriefSerializer(source='user', read_only=True)

    class Meta:
        model = WorksheetLog
        fields = ['id', 'task', 'user', 'user_detail', 'start_time', 'end_time',
                  'remarks', 'hours_spent', 'hours_logged', 'logged_on']
        read_only_fields = ['user', 'logged_on', 'hours_logged']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


# ─── TASK (list / detail) ─────────────────────────────────────────────────────

class TaskLabelSerializer(serializers.ModelSerializer):
    label_detail = LabelSerializer(source='label', read_only=True)

    class Meta:
        model = TaskLabel
        fields = ['id', 'task', 'label', 'label_detail']


class TaskListSerializer(serializers.ModelSerializer):
    """Flat list serializer — fast."""
    priority_detail = TaskPrioritySerializer(source='priority', read_only=True)
    assignee_detail = UserBriefSerializer(source='assignee', read_only=True)
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)
    is_overdue = serializers.ReadOnlyField()
    label_list = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'id', 'title', 'description', 'status', 'task_type', 'extended_status',
            'start_date', 'start_time', 'end_date', 'end_time',
            'startdatetime', 'enddatetime', 'is_allday',
            'priority', 'priority_detail',
            'project', 'task_list',
            'assignee', 'assignee_detail',
            'created_by', 'created_by_detail',
            'color', 'completed_percentage', 'is_overdue',
            'assessment_status', 'ticket_id', 'external_ref',
            'is_recurring', 'recurring_type',
            'is_reminder', 'reminder_type', 'reminder_before', 'reminder_date',
            'label_list', 'created_on', 'last_modified',
        ]
        read_only_fields = ['created_by', 'created_on', 'last_modified']

    def get_label_list(self, obj):
        return [tl.label.name for tl in obj.labels.select_related('label').all()]

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class TaskDetailSerializer(TaskListSerializer):
    """Full detail with nested children."""
    members = TaskMemberSerializer(many=True, read_only=True)
    attachments = TaskAttachmentSerializer(many=True, read_only=True)
    notes = TaskNoteSerializer(many=True, read_only=True)
    checklist = TaskCheckListSerializer(many=True, read_only=True)
    labels = TaskLabelSerializer(many=True, read_only=True)
    status_updates = TaskStatusUpdateSerializer(many=True, read_only=True)
    time_logs = WorksheetLogSerializer(many=True, read_only=True)
    reminders = TaskReminderSerializer(many=True, read_only=True)
    subtasks = serializers.SerializerMethodField()

    class Meta(TaskListSerializer.Meta):
        fields = TaskListSerializer.Meta.fields + [
            'members', 'attachments', 'notes', 'checklist',
            'labels', 'status_updates', 'time_logs', 'reminders', 'subtasks',
            'is_sla', 'include_weekend', 'completed_on', 'reportee',
            'recurring_start_date', 'recurring_end_date', 'recurring_every',
        ]

    def get_subtasks(self, obj):
        children = TaskHierarchy.objects.filter(parent=obj).select_related('child')
        return TaskListSerializer(
            [h.child for h in children], many=True, context=self.context
        ).data


# ─── PROJECT ──────────────────────────────────────────────────────────────────

class ProjectStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectStatus
        fields = ['id', 'name', 'code', 'color', 'order']


class TaskListInProjectSerializer(serializers.ModelSerializer):
    task_count = serializers.SerializerMethodField()

    class Meta:
        model = TaskList
        fields = ['id', 'name', 'description', 'color', 'order', 'project', 'task_count']

    def get_task_count(self, obj):
        return obj.tasks.count()


class ProjectMemberSerializer(serializers.ModelSerializer):
    user_detail = UserBriefSerializer(source='user', read_only=True)

    class Meta:
        model = ProjectMember
        fields = ['id', 'project', 'user', 'user_detail', 'type', 'membership']


class ProjectCommentSerializer(serializers.ModelSerializer):
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)

    class Meta:
        model = ProjectComment
        fields = ['id', 'project', 'comment', 'created_by', 'created_by_detail', 'created_on', 'updated_on']
        read_only_fields = ['created_by', 'created_on', 'updated_on']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ProjectStatusUpdateSerializer(serializers.ModelSerializer):
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)

    class Meta:
        model = ProjectStatusUpdate
        fields = ['id', 'project', 'title', 'status', 'description',
                  'created_by', 'created_by_detail', 'created_on', 'last_modified']
        read_only_fields = ['created_by', 'created_on', 'last_modified']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ProjectListSerializer(serializers.ModelSerializer):
    status_detail = ProjectStatusSerializer(source='status', read_only=True)
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)
    assignee_detail = UserBriefSerializer(source='assignee', read_only=True)
    task_count = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = [
            'id', 'title', 'description', 'privacy', 'assessment_status', 'extended_status',
            'start_date', 'end_date', 'is_deleted',
            'status', 'status_detail',
            'created_by', 'created_by_detail',
            'assignee', 'assignee_detail',
            'task_count', 'member_count',
            'created_on', 'last_modified',
        ]
        read_only_fields = ['created_by', 'created_on', 'last_modified']

    def get_task_count(self, obj):
        return obj.tasks.count()

    def get_member_count(self, obj):
        return obj.members.count()

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ProjectDetailSerializer(ProjectListSerializer):
    members = ProjectMemberSerializer(many=True, read_only=True)
    task_lists = TaskListInProjectSerializer(many=True, read_only=True)
    comments = ProjectCommentSerializer(many=True, read_only=True)
    status_updates = ProjectStatusUpdateSerializer(many=True, read_only=True)

    class Meta(ProjectListSerializer.Meta):
        fields = ProjectListSerializer.Meta.fields + [
            'members', 'task_lists', 'comments', 'status_updates'
        ]


# ─── WORK GROUP ───────────────────────────────────────────────────────────────

class WorkGroupSerializer(serializers.ModelSerializer):
    created_by_detail = UserBriefSerializer(source='created_by', read_only=True)

    class Meta:
        model = WorkGroup
        fields = ['id', 'name', 'module', 'created_by', 'created_by_detail', 'created_on']
        read_only_fields = ['created_by', 'created_on']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


# ─── TASK DASHBOARD SUMMARY ───────────────────────────────────────────────────

class TaskDashboardSerializer(serializers.Serializer):
    total_tasks = serializers.IntegerField()
    open_tasks = serializers.IntegerField()
    in_progress = serializers.IntegerField()
    on_hold = serializers.IntegerField()
    completed = serializers.IntegerField()
    overdue = serializers.IntegerField()
    my_tasks = serializers.IntegerField()
    total_projects = serializers.IntegerField()
    active_projects = serializers.IntegerField()
