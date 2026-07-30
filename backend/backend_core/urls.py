from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from backend_core.views import GetCSRFToken, LoginView, LogoutView, UserProfileView

urlpatterns = [
    path('admin/', admin.site.urls),

    # Auth — legacy session-based (keep for web dashboard)
    path('api/csrf_cookie/', GetCSRFToken.as_view(), name='csrf_cookie'),
    path('api/login/', LoginView.as_view(), name='login'),
    path('api/logout/', LogoutView.as_view(), name='logout'),
    path('api/profile/', UserProfileView.as_view(), name='profile'),

    # Auth — JWT (for mobile app)
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Existing CRM apps
    path('api/dashboard/', include('dashboard.urls')),
    path('api/crm/', include('crm.urls')),
    path('api/system_admin/', include('system_admin.urls')),

    # NEW: Tasks & Projects
    path('api/tasks/', include('tasks.urls')),

    # NEW: Gemini AI features
    path('api/ai/', include('ai.urls')),

    # ── Mobile API v1  (/api/mobile/v1/...) ──────────────────────────────────
    # Matches the base URL in the CRM Mobile API Developer Guide V1
    path('api/mobile/v1/token/',         TokenObtainPairView.as_view(), name='mobile_token_obtain'),
    path('api/mobile/v1/token/refresh/', TokenRefreshView.as_view(),   name='mobile_token_refresh'),
    path('api/mobile/v1/profile/',       UserProfileView.as_view(),    name='mobile_profile'),
    path('api/mobile/v1/dashboard/',     include('dashboard.urls')),
    path('api/mobile/v1/crm/',           include('crm.urls')),
    path('api/mobile/v1/admin/',         include('system_admin.urls')),  # guide uses /admin/ prefix
    path('api/mobile/v1/tasks/',         include('tasks.urls')),
    path('api/mobile/v1/ai/',            include('ai.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
