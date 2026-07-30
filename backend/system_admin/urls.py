from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, RoleViewSet, SubsidiaryViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'roles', RoleViewSet)
router.register(r'subsidiaries', SubsidiaryViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
