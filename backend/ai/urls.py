from django.urls import path
from .views import (
    # Original 6 endpoints
    TaskSuggestionsView,
    SummarizeNotesView,
    OpportunityScoreView,
    DraftEmailView,
    TaskDescriptionView,
    ProjectSummaryView,
    # New eval-spec features (5)
    LeadScoreView,
    SentimentAnalysisView,
    CategorizationView,
    ActionItemsView,
    ContactNormalizationView,
    # Remaining AI Features (5)
    ChatAssistantView,
    StalledDealDetectionView,
    MeetingPrepView,
    NLRecordCreationView,
    NLDatabaseQueryView,
)

urlpatterns = [
    # ── Original endpoints ──────────────────────────────────────────────────
    path('task-suggestions/',   TaskSuggestionsView.as_view(),  name='ai-task-suggestions'),
    path('summarize-notes/',    SummarizeNotesView.as_view(),   name='ai-summarize-notes'),
    path('opportunity-score/',  OpportunityScoreView.as_view(), name='ai-opportunity-score'),
    path('draft-email/',        DraftEmailView.as_view(),       name='ai-draft-email'),
    path('task-description/',   TaskDescriptionView.as_view(),  name='ai-task-description'),
    path('project-summary/',    ProjectSummaryView.as_view(),   name='ai-project-summary'),

    # ── New eval-spec AI features ───────────────────────────────────────────
    path('lead-score/',         LeadScoreView.as_view(),            name='ai-lead-score'),
    path('sentiment/',          SentimentAnalysisView.as_view(),    name='ai-sentiment'),
    path('categorize/',         CategorizationView.as_view(),       name='ai-categorize'),
    path('action-items/',       ActionItemsView.as_view(),          name='ai-action-items'),
    path('normalize-contact/',  ContactNormalizationView.as_view(), name='ai-normalize-contact'),

    # ── Remaining AI Features ───────────────────────────────────────────────
    path('chat-assistant/',     ChatAssistantView.as_view(),        name='ai-chat-assistant'),
    path('stalled-deal/',       StalledDealDetectionView.as_view(), name='ai-stalled-deal'),
    path('meeting-prep/',       MeetingPrepView.as_view(),          name='ai-meeting-prep'),
    path('nl-record-creation/', NLRecordCreationView.as_view(),     name='ai-nl-record-creation'),
    path('nl-db-query/',        NLDatabaseQueryView.as_view(),      name='ai-nl-db-query'),
]
