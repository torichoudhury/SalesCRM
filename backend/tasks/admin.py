from django.contrib import admin
from .models import (
    Task, TaskList, TaskMember, TaskAttachment, TaskNote, TaskNoteAttachment,
    TaskCheckList, TaskLabel, Label, TaskPriority, TaskHierarchy,
    TaskStatusUpdate, TaskRejectComment, TaskReminder, TaskReminderMember,
    TaskPlanner, Project, ProjectStatus, ProjectStatusUpdate,
    ProjectMember, ProjectComment, BookmarkProject,
    TrackTask, TrackProject, WorksheetLog, WorkGroup, WorkGroupProject,
)


@admin.register(TaskPriority)
class TaskPriorityAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'color', 'order']
    ordering = ['order']


@admin.register(Label)
class LabelAdmin(admin.ModelAdmin):
    list_display = ['name', 'color', 'created_by']
    search_fields = ['name']


@admin.register(ProjectStatus)
class ProjectStatusAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'color', 'order']
    ordering = ['order']


class ProjectMemberInline(admin.TabularInline):
    model = ProjectMember
    extra = 0
    raw_id_fields = ['user']


class TaskListInline(admin.TabularInline):
    model = TaskList
    extra = 0


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ['title', 'created_by', 'status', 'privacy', 'assessment_status', 'is_deleted', 'created_on']
    list_filter = ['privacy', 'assessment_status', 'is_deleted', 'status']
    search_fields = ['title', 'description']
    raw_id_fields = ['created_by', 'assignee', 'status']
    inlines = [ProjectMemberInline, TaskListInline]
    date_hierarchy = 'created_on'


@admin.register(TaskList)
class TaskListAdmin(admin.ModelAdmin):
    list_display = ['name', 'project', 'order', 'color']
    list_filter = ['project']
    search_fields = ['name', 'project__title']


class TaskMemberInline(admin.TabularInline):
    model = TaskMember
    extra = 0
    raw_id_fields = ['user']


class TaskCheckListInline(admin.TabularInline):
    model = TaskCheckList
    extra = 0
    raw_id_fields = ['created_by']


class TaskAttachmentInline(admin.TabularInline):
    model = TaskAttachment
    extra = 0


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'status', 'task_type', 'assignee', 'created_by',
        'project', 'priority', 'end_date', 'assessment_status', 'created_on'
    ]
    list_filter = ['status', 'task_type', 'assessment_status', 'is_recurring', 'is_sla']
    search_fields = ['title', 'description', 'ticket_id', 'external_ref']
    raw_id_fields = ['assignee', 'created_by', 'reportee', 'priority', 'project', 'task_list']
    inlines = [TaskMemberInline, TaskCheckListInline, TaskAttachmentInline]
    date_hierarchy = 'created_on'
    readonly_fields = ['created_on', 'last_modified', 'completed_on']
    fieldsets = (
        ('Core', {
            'fields': ('title', 'description', 'status', 'extended_status',
                       'task_type', 'color', 'priority', 'assessment_status')
        }),
        ('Dates', {
            'fields': ('start_date', 'start_time', 'end_date', 'end_time',
                       'startdatetime', 'enddatetime', 'is_allday',
                       'completed_on', 'completed_percentage')
        }),
        ('Assignment', {
            'fields': ('assignee', 'created_by', 'reportee', 'project', 'task_list')
        }),
        ('Recurrence', {
            'classes': ('collapse',),
            'fields': ('is_recurring', 'recurring_type', 'recurring_start_date', 'recurring_end_date',
                       'recurring_every', 'recurring_day', 'recurring_monthly_type',
                       'recurring_monthly_date', 'recurring_monthly_week', 'recurring_monthly_weekday',
                       'recurring_yearly_type', 'recurring_yearly_month', 'recurring_yearly_date',
                       'recurring_yearly_week', 'recurring_yearly_weekday')
        }),
        ('Reminder / SLA', {
            'classes': ('collapse',),
            'fields': ('is_sla', 'is_reminder', 'reminder_type', 'reminder_before',
                       'reminder_date', 'is_reminderall')
        }),
        ('Metadata', {
            'classes': ('collapse',),
            'fields': ('external_ref', 'ticket_id', 'repeat_id', 'timezone',
                       'include_weekend', 'created_on', 'last_modified')
        }),
    )


@admin.register(TaskNote)
class TaskNoteAdmin(admin.ModelAdmin):
    list_display = ['task', 'created_by', 'created_on']
    search_fields = ['notes', 'task__title']
    raw_id_fields = ['task', 'created_by']


@admin.register(TaskAttachment)
class TaskAttachmentAdmin(admin.ModelAdmin):
    list_display = ['title', 'task', 'uploaded_by', 'created_on']
    raw_id_fields = ['task', 'uploaded_by']


@admin.register(TaskCheckList)
class TaskCheckListAdmin(admin.ModelAdmin):
    list_display = ['description', 'task', 'is_completed', 'created_by']
    list_filter = ['is_completed']
    raw_id_fields = ['task', 'created_by']


@admin.register(TaskStatusUpdate)
class TaskStatusUpdateAdmin(admin.ModelAdmin):
    list_display = ['task', 'status', 'created_by', 'created_on']
    list_filter = ['status']
    raw_id_fields = ['task', 'created_by']


@admin.register(TaskReminder)
class TaskReminderAdmin(admin.ModelAdmin):
    list_display = ['name', 'task', 'reminder_type']
    raw_id_fields = ['task']


@admin.register(TaskPlanner)
class TaskPlannerAdmin(admin.ModelAdmin):
    list_display = ['task', 'startdatetime', 'status', 'created_by']
    list_filter = ['status']
    raw_id_fields = ['task', 'created_by']


@admin.register(WorksheetLog)
class WorksheetLogAdmin(admin.ModelAdmin):
    list_display = ['task', 'user', 'start_time', 'end_time', 'hours_logged', 'logged_on']
    raw_id_fields = ['task', 'user']
    date_hierarchy = 'logged_on'

    def hours_logged(self, obj):
        return obj.hours_logged
    hours_logged.short_description = 'Hours'


@admin.register(WorkGroup)
class WorkGroupAdmin(admin.ModelAdmin):
    list_display = ['name', 'module', 'created_by', 'created_on']
    search_fields = ['name']
    raw_id_fields = ['created_by']


@admin.register(BookmarkProject)
class BookmarkProjectAdmin(admin.ModelAdmin):
    list_display = ['user', 'project']
    raw_id_fields = ['user', 'project']


admin.site.register(TaskMember)
admin.site.register(TaskLabel)
admin.site.register(TaskHierarchy)
admin.site.register(TaskRejectComment)
admin.site.register(TaskReminderMember)
admin.site.register(ProjectMember)
admin.site.register(ProjectComment)
admin.site.register(ProjectStatusUpdate)
admin.site.register(TrackTask)
admin.site.register(TrackProject)
admin.site.register(WorkGroupProject)
