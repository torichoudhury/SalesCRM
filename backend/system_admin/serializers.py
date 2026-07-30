from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Role, Subsidiary

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'is_active', 'date_joined']

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = '__all__'

class SubsidiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Subsidiary
        fields = '__all__'
