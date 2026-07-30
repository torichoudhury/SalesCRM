from rest_framework import viewsets
from rest_framework.permissions import IsAdminUser
from django.contrib.auth.models import User
from .models import Role, Subsidiary
from .serializers import UserSerializer, RoleSerializer, SubsidiarySerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]

class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.all().order_by('name')
    serializer_class = RoleSerializer
    permission_classes = [IsAdminUser]

class SubsidiaryViewSet(viewsets.ModelViewSet):
    queryset = Subsidiary.objects.all().order_by('name')
    serializer_class = SubsidiarySerializer
    permission_classes = [IsAdminUser]
