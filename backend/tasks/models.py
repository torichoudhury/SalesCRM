from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


# ─── PRIORITY ─────────────────────────────────────────────────────────────────

class TaskPriority(models.Model):
    name = models.CharField(max_length=20)
    code = models.CharField(max_length=1)
    color = models.CharField(max_length=7, default="#fad6b7")
    order = models.IntegerField(default=10)
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='task_priorities'
    )

    class Meta:
        db_table = "TaskPriority"
        ordering = ['order']

    def __str__(self):
        return self.name


# ─── LABEL ────────────────────────────────────────────────────────────────────

class Label(models.Model):
    name = models.CharField(max_length=30)
    color = models.CharField(max_length=7)
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='task_labels'
    )

    class Meta:
        db_table = "Label"

    def __str__(self):
        return self.name


# ─── PROJECT STATUS ───────────────────────────────────────────────────────────

class ProjectStatus(models.Model):
    name = models.CharField(max_length=50)
    code = models.CharField(max_length=1)
    order = models.IntegerField(default=10)
    color = models.CharField(max_length=7, default="#828383")

    class Meta:
        db_table = "ProjectStatus"
        ordering = ['order']

    def __str__(self):
        return self.name


# ─── PROJECT ──────────────────────────────────────────────────────────────────

class Project(models.Model):
    PRIVACY_CHOICES = (
        ("A", "Private"),
        ("B", "Public"),
    )
    ASSESSMENT_STATUS = [
        ("A", "On-Track"),
        ("B", "Delayed"),
    ]
    EXTENDED_STATUS_CHOICES = [
        ("A", "Archived"),
    ]

    title = models.CharField(max_length=100)
    description = models.TextField(blank=True, default='')
    start_date = models.DateTimeField(blank=True, null=True)
    end_date = models.DateTimeField(blank=True, null=True)
    privacy = models.CharField(max_length=1, choices=PRIVACY_CHOICES, default="A")
    created_by = models.ForeignKey(
        User, on_delete=models.DO_NOTHING, db_column="fkRoleuser", related_name="projects_created"
    )
    assignee = models.ForeignKey(
        User, on_delete=models.DO_NOTHING, db_column="fkAssignee",
        null=True, blank=True, related_name="projects_assigned"
    )
    status = models.ForeignKey(
        ProjectStatus, on_delete=models.DO_NOTHING, db_column="fkStatus", null=True, blank=True
    )
    is_deleted = models.BooleanField(default=False)
    assessment_status = models.CharField(max_length=1, choices=ASSESSMENT_STATUS, default="A")
    extended_status = models.CharField(max_length=1, choices=EXTENDED_STATUS_CHOICES, null=True, blank=True)
    created_on = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "Project"
        ordering = ['-created_on']

    def __str__(self):
        return f"{self.title} ({self.pk})"


class Subproject(models.Model):
    parent = models.ForeignKey(
        Project, on_delete=models.CASCADE, db_column="fksubproject", related_name="subprojects"
    )
    child = models.ForeignKey(
        Project, on_delete=models.CASCADE, db_column="fkproject", related_name="parent_project"
    )

    class Meta:
        db_table = "Subproject"


class ProjectStatusUpdate(models.Model):
    title = models.CharField(max_length=150, null=True, blank=True)
    status = models.ForeignKey(
        ProjectStatus, on_delete=models.CASCADE, db_column="fkStatus", null=True, blank=True
    )
    description = models.TextField()
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser")
    project = models.ForeignKey(Project, on_delete=models.CASCADE, db_column="fkProject", related_name="status_updates")
    created_on = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "ProjectStatusUpdate"
        ordering = ['-created_on']


class ProjectMember(models.Model):
    MEMBER_TYPE = (
        ("A", "Can Edit"),
        ("V", "Can View"),
        ("C", "Can Comment"),
        ("D", "Can Delete"),
    )
    MEMBERSHIP_CHOICES = (
        ("P", "Project"),
        ("T", "Task"),
    )

    project = models.ForeignKey(Project, on_delete=models.CASCADE, db_column="fkProject", related_name="members")
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser")
    type = models.CharField(max_length=1, choices=MEMBER_TYPE)
    membership = models.CharField(max_length=1, choices=MEMBERSHIP_CHOICES, default="P")

    class Meta:
        db_table = "ProjectMember"
        unique_together = [['project', 'user']]


class ProjectComment(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, db_column="fkproject", related_name="comments")
    created_by = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser")
    comment = models.TextField()
    created_on = models.DateTimeField(auto_now_add=True)
    updated_on = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "ProjectComment"
        ordering = ['created_on']


class ProjectCommentHierarchy(models.Model):
    parent = models.ForeignKey(
        ProjectComment, on_delete=models.DO_NOTHING, db_column="fkParent", related_name="comment_parent"
    )
    child = models.ForeignKey(
        ProjectComment, on_delete=models.CASCADE, db_column="fkChild", related_name="comment_child"
    )

    class Meta:
        db_table = "ProjectCommentHeirarchy"  # original spelling preserved


class BookmarkProject(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser", related_name="bookmarked_projects")
    project = models.ForeignKey(Project, on_delete=models.CASCADE, db_column="fkProject")

    class Meta:
        db_table = "BookmarkProject"
        unique_together = [['user', 'project']]


# ─── TASK LIST ────────────────────────────────────────────────────────────────

class TaskList(models.Model):
    name = models.CharField(max_length=50)
    description = models.TextField(blank=True, null=True)
    color = models.CharField(max_length=7, default="#828383")
    order = models.IntegerField(default=0)
    project = models.ForeignKey(
        Project, on_delete=models.CASCADE, db_column="fkProject", related_name="task_lists"
    )

    class Meta:
        db_table = "TaskList"
        ordering = ['order']

    def __str__(self):
        return f"{self.project.title} / {self.name}"


# ─── TASK ─────────────────────────────────────────────────────────────────────

class Task(models.Model):
    STATUS_CHOICES = [
        ("O", "Open"),
        ("P", "In Progress"),
        ("H", "On Hold"),
        ("C", "Complete"),
    ]
    RECURRING_TYPE = [
        ("E", "Every Week Day"),
        ("D", "Daily"),
        ("W", "Weekly"),
        ("M", "Monthly"),
        ("Y", "Yearly"),
    ]
    REMINDER_TYPE_CHOICES = (
        ("M", "Minutes"),
        ("H", "Hours"),
        ("D", "Daily"),
    )
    RECURRING_MONTHLY_WEEK_CHOICES = [
        (1, "First"), (2, "Second"), (3, "Third"), (4, "Fourth"), (5, "Last")
    ]
    MONTHLY_TYPE_CHOICES = [("D", "Day"), ("W", "Week")]
    YEARLY_TYPE_CHOICES = [("D", "Day"), ("W", "Week")]
    TASKTYPE_CHOICES = [
        ("N", "Activity"),
        ("A", "Appointment"),
        ("M", "Meeting"),
        ("E", "Event"),
        ("C", "Call"),
        ("B", "Client Meeting"),
        ("D", "BD Call"),
        ("F", "Client Interview"),
        ("J", "Face 2 Face"),
    ]
    ASSESSMENT_STATUS = [
        ("A", "On-Track"),
        ("B", "Delayed"),
    ]
    EXTENDED_STATUS_CHOICES = [
        ("A", "Archived"),
    ]

    title = models.CharField(max_length=100, verbose_name="Task Title")
    description = models.TextField(null=True, blank=True)
    start_date = models.DateField(blank=True, null=True)
    start_time = models.TimeField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    end_time = models.TimeField(blank=True, null=True)
    startdatetime = models.DateTimeField(blank=True, null=True)
    enddatetime = models.DateTimeField(blank=True, null=True)
    is_allday = models.BooleanField(default=False)

    # Recurrence
    is_recurring = models.BooleanField(default=False)
    recurring_type = models.CharField(max_length=1, choices=RECURRING_TYPE, blank=True, null=True)
    recurring_start_date = models.DateField(blank=True, null=True)
    recurring_end_date = models.DateField(blank=True, null=True)
    recurring_every = models.IntegerField(blank=True, null=True)
    recurring_day = models.CharField(max_length=13, blank=True, null=True)
    recurring_monthly_type = models.CharField(max_length=1, choices=MONTHLY_TYPE_CHOICES, blank=True, null=True)
    recurring_monthly_date = models.IntegerField(blank=True, null=True)
    recurring_monthly_week = models.IntegerField(choices=RECURRING_MONTHLY_WEEK_CHOICES, blank=True, null=True)
    recurring_monthly_weekday = models.IntegerField(blank=True, null=True)
    recurring_yearly_type = models.CharField(max_length=1, choices=YEARLY_TYPE_CHOICES, blank=True, null=True)
    recurring_yearly_month = models.IntegerField(blank=True, null=True)
    recurring_yearly_date = models.IntegerField(blank=True, null=True)
    recurring_yearly_week = models.IntegerField(choices=RECURRING_MONTHLY_WEEK_CHOICES, blank=True, null=True)
    recurring_yearly_weekday = models.IntegerField(blank=True, null=True)

    # Core
    priority = models.ForeignKey(
        TaskPriority, on_delete=models.SET_NULL, db_column='fkTaskPriority', blank=True, null=True
    )
    project = models.ForeignKey(
        Project, on_delete=models.CASCADE, db_column="fkproject", null=True, blank=True, related_name="tasks"
    )
    task_list = models.ForeignKey(
        TaskList, on_delete=models.SET_NULL, db_column="fktasklist", null=True, blank=True, related_name="tasks"
    )
    color = models.CharField(max_length=7, blank=True, null=True)
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default="O")
    extended_status = models.CharField(max_length=1, choices=EXTENDED_STATUS_CHOICES, null=True, blank=True)
    task_type = models.CharField(max_length=1, choices=TASKTYPE_CHOICES, blank=True, null=True)

    # Assignments
    assignee = models.ForeignKey(
        User, related_name="tasks_assigned", on_delete=models.DO_NOTHING,
        db_column="fkTaskowner", blank=True, null=True
    )
    created_by = models.ForeignKey(
        User, on_delete=models.DO_NOTHING, db_column="fkCreated_by", related_name="tasks_created"
    )
    reportee = models.ForeignKey(
        User, on_delete=models.SET_NULL, db_column='fkReportee', null=True, blank=True,
        related_name="tasks_to_report"
    )

    # Timing & progress
    timezone = models.CharField(max_length=30, null=True, blank=True)
    completed_percentage = models.IntegerField(default=0)
    include_weekend = models.BooleanField(default=False)
    completed_on = models.DateTimeField(blank=True, null=True)
    assessment_status = models.CharField(max_length=1, choices=ASSESSMENT_STATUS, default="A")

    # Reminders
    is_sla = models.BooleanField(default=False)
    is_reminder = models.BooleanField(default=False)
    reminder_type = models.CharField(max_length=1, choices=REMINDER_TYPE_CHOICES, blank=True, null=True)
    reminder_before = models.IntegerField(default=0, null=True, blank=True)
    reminder_date = models.DateTimeField(blank=True, null=True)
    is_reminderall = models.BooleanField(blank=True, null=True)

    # Misc
    external_ref = models.CharField(max_length=250, null=True, blank=True)
    ticket_id = models.CharField(max_length=25, blank=True, null=True)
    repeat_id = models.IntegerField(null=True, blank=True)

    created_on = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "Task"
        ordering = ['-created_on']

    def __str__(self):
        return f'{self.title} [#{self.id}]'

    def save(self, *args, **kwargs):
        if self.task_list and not self.project:
            self.project = self.task_list.project
        if self.status == 'C' and not self.completed_on:
            self.completed_on = timezone.now()
        super().save(*args, **kwargs)

    @property
    def is_overdue(self):
        if self.end_date and self.status in ("O", "P"):
            import datetime as dt
            end_time = self.end_time or dt.time(23, 59, 59)
            end_dt = dt.datetime.combine(self.end_date, end_time)
            end_dt = timezone.make_aware(end_dt) if timezone.is_naive(end_dt) else end_dt
            return end_dt <= timezone.now()
        return False


class TaskHierarchy(models.Model):
    """Parent-child subtask relationship."""
    parent = models.ForeignKey(
        Task, related_name="subtask_parents", on_delete=models.SET_NULL,
        db_column="fkTaskparent", null=True, blank=True
    )
    child = models.ForeignKey(
        Task, related_name="subtask_children", on_delete=models.CASCADE,
        db_column="fkTaskchild"
    )

    class Meta:
        db_table = "TaskHierarchy"
        unique_together = [['parent', 'child']]


class TaskMember(models.Model):
    MEMBER_TYPE = (
        ("A", "Can Edit"),
        ("V", "Can View"),
        ("C", "Can Comment"),
        ("D", "Can Delete"),
    )
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fktask", related_name="members")
    user = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser")
    type = models.CharField(max_length=1, choices=MEMBER_TYPE)

    class Meta:
        db_table = "TaskMember"
        unique_together = [['task', 'user']]

    def __str__(self):
        return f"{self.user} ({self.get_type_display()}) on Task #{self.task_id}"


def task_attachment_upload_to(instance, filename):
    return f"tasks/task_{instance.task_id}/attachments/{filename}"


class TaskAttachment(models.Model):
    title = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    file = models.FileField(upload_to=task_attachment_upload_to)
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fkTask", related_name="attachments")
    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_on = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "TaskAttachment"

    def __str__(self):
        return self.title


class TaskNote(models.Model):
    """Threaded comment on a task."""
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fkTask", related_name="notes")
    created_by = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser")
    notes = models.TextField()
    created_on = models.DateTimeField(auto_now_add=True)
    updated_on = models.DateTimeField(auto_now=True)
    is_auto_remove = models.BooleanField(default=False)
    remove_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = "TaskNote"
        ordering = ['created_on']

    def __str__(self):
        return f"Comment on '{self.task.title}'"


def task_note_attachment_upload_to(instance, filename):
    return f"tasks/task_{instance.note.task_id}/note_{instance.note_id}/{filename}"


class TaskNoteAttachment(models.Model):
    file = models.FileField(upload_to=task_note_attachment_upload_to)
    note = models.ForeignKey(TaskNote, on_delete=models.CASCADE, db_column="fkTaskNote", related_name="attachments")
    created_on = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "TaskNoteAttachment"


class TaskNoteHierarchy(models.Model):
    parent = models.ForeignKey(
        TaskNote, on_delete=models.DO_NOTHING, db_column="fkParent", related_name="note_parent"
    )
    child = models.ForeignKey(
        TaskNote, on_delete=models.CASCADE, db_column="fkChild", related_name="note_child"
    )

    class Meta:
        db_table = "TaskNoteHeirarchy"  # original spelling preserved


class TaskCheckList(models.Model):
    description = models.TextField()
    is_completed = models.BooleanField(default=False)
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fkTask", related_name="checklist")
    created_by = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser")
    created_on = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "TaskCheckList"

    def __str__(self):
        return f"{self.task.title} — Checklist Item #{self.id}"


class TaskLabel(models.Model):
    label = models.ForeignKey(Label, on_delete=models.CASCADE, db_column="fkLabel")
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fkTask", related_name="labels")

    class Meta:
        db_table = "TaskLabel"
        unique_together = [['label', 'task']]


class TaskStatusUpdate(models.Model):
    STATUS_CHOICES = [
        ("O", "Open"),
        ("P", "In Progress"),
        ("H", "On Hold"),
        ("C", "Complete"),
    ]
    title = models.CharField(max_length=150, null=True, blank=True)
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default="O", null=True, blank=True)
    description = models.TextField()
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser")
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column='fkTask', related_name="status_updates")
    created_on = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "TaskStatusUpdate"
        ordering = ['-created_on']


class TaskRejectComment(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fkTask", related_name="reject_comments")
    comment = models.TextField()
    created_on = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkCreated_by")

    class Meta:
        db_table = "TaskRejectComment"

    def __str__(self):
        return f'Reject Comment on "{self.task.title}"'


class TaskReminder(models.Model):
    REMINDER_TYPE = (
        ("M", "Minutes"),
        ("H", "Hours"),
        ("D", "Days"),
    )
    name = models.CharField(max_length=50)
    reminder_type = models.CharField(max_length=1, choices=REMINDER_TYPE, default="H")
    day = models.IntegerField(null=True, blank=True)
    hour = models.IntegerField(null=True, blank=True)
    minute = models.IntegerField(null=True, blank=True)
    time = models.TimeField(null=True, blank=True)
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column='fkTask', related_name="reminders")
    remind_assignee = models.BooleanField(default=True)
    remind_creator = models.BooleanField(default=True)
    remind_members = models.BooleanField(default=True)
    remind_custom_users = models.BooleanField(default=False)
    parent = models.ForeignKey(
        "self", on_delete=models.CASCADE, db_column="fkParent", null=True, blank=True, related_name="child_reminders"
    )

    class Meta:
        db_table = "TaskReminder"

    def __str__(self):
        return self.name


class TaskReminderMember(models.Model):
    reminder = models.ForeignKey(TaskReminder, on_delete=models.CASCADE, db_column='fkTaskReminder', related_name="members")
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser")

    class Meta:
        db_table = "TaskReminderMember"


class TaskPlanner(models.Model):
    STATUS_CHOICES = (
        ("S", "Scheduled"),
        ("U", "Yet to Schedule"),
    )
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column='fkTask', related_name="planners")
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    startdatetime = models.DateTimeField()
    enddatetime = models.DateTimeField(null=True, blank=True)
    remarks = models.TextField(null=True, blank=True)
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default='U')
    created_by = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser")
    created_on = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "TaskPlanner"
        ordering = ['startdatetime']


# ─── TRACKER ──────────────────────────────────────────────────────────────────

class TrackTask(models.Model):
    TRACK_STATUS_CHOICES = [
        ("N", "Disabled"), ("D", "Daily"), ("W", "Weekly"), ("M", "Monthly")
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser", related_name="tracked_tasks")
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column="fkTask", related_name="trackers")
    track_on = models.CharField(max_length=1, choices=TRACK_STATUS_CHOICES, default="N")

    class Meta:
        db_table = "TrackTask"
        unique_together = [['user', 'task']]


class TrackProject(models.Model):
    TRACK_STATUS_CHOICES = [
        ("N", "Disabled"), ("D", "Daily"), ("W", "Weekly"), ("M", "Monthly")
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_column="fkRoleuser")
    project = models.ForeignKey(Project, on_delete=models.CASCADE, db_column="fkProject")
    track_on = models.CharField(max_length=1, choices=TRACK_STATUS_CHOICES, default="N")

    class Meta:
        db_table = "TrackProject"
        unique_together = [['user', 'project']]


# ─── WORKSHEET / TIME TRACKING ────────────────────────────────────────────────

class WorksheetLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser", related_name="worksheet_logs")
    task = models.ForeignKey(Task, on_delete=models.CASCADE, db_column='fkTask', related_name="time_logs")
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(null=True, blank=True)
    remarks = models.TextField(null=True, blank=True)
    logged_on = models.DateTimeField(auto_now_add=True)
    hours_spent = models.DecimalField(max_digits=19, decimal_places=2, null=True, blank=True, default=0)

    class Meta:
        db_table = "worksheetLog"
        ordering = ['-logged_on']

    @property
    def hours_logged(self):
        from decimal import Decimal
        end = self.end_time or timezone.now()
        delta = end - self.start_time
        return round(Decimal(delta.total_seconds()) / Decimal(3600), 2)


# ─── WORK GROUPS ─────────────────────────────────────────────────────────────

class WorkGroup(models.Model):
    name = models.CharField(max_length=50)
    module = models.CharField(max_length=50, default='tasks')
    created_by = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_column="fkRoleuser")
    created_on = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "WorkGroup"
        unique_together = [['name', 'created_by', 'module']]

    def __str__(self):
        return self.name


class WorkGroupHierarchy(models.Model):
    parent = models.ForeignKey(
        WorkGroup, related_name="child_groups", on_delete=models.CASCADE,
        db_column="fkParent", null=True, blank=True
    )
    child = models.ForeignKey(
        WorkGroup, related_name="parent_groups", on_delete=models.CASCADE, db_column="fkChild"
    )

    class Meta:
        db_table = "WorkGroupHierarchy"


class WorkGroupProject(models.Model):
    work_group = models.ForeignKey(WorkGroup, on_delete=models.CASCADE, db_column="fkWorkgroup", related_name="projects")
    project = models.ForeignKey(Project, on_delete=models.CASCADE, db_column="fkProject")

    class Meta:
        db_table = "WorkGroupProject"
        unique_together = [['work_group', 'project']]
