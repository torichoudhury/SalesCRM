from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsTaskOwnerOrMember(BasePermission):
    """
    Allow full access to the task creator/assignee.
    Allow read-only access to task members.
    """
    message = "You do not have permission to access this task."

    def has_object_permission(self, request, view, obj):
        user = request.user
        # Creator always has access
        if obj.created_by_id == user.id:
            return True
        # Assignee has access
        if obj.assignee_id == user.id:
            return True
        # Members: check type
        member = obj.members.filter(user=user).first()
        if member:
            if request.method in SAFE_METHODS:
                return True
            return member.type in ('A', 'D')
        return False


class IsProjectOwnerOrMember(BasePermission):
    """
    Allow full access to the project creator.
    Allow read/write to Can Edit / Can Delete members.
    Allow read-only to Can View / Can Comment members.
    """
    message = "You do not have permission to access this project."

    def has_object_permission(self, request, view, obj):
        user = request.user
        if obj.created_by_id == user.id:
            return True
        member = obj.members.filter(user=user).first()
        if member:
            if request.method in SAFE_METHODS:
                return True
            return member.type in ('A', 'D')
        return False
