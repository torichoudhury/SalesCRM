# TALXOne Sales CRM

TALXOne Sales CRM is a premium, full-stack enterprise relationship management tool. It features a robust Python Django REST Framework backend paired with a cross-platform Flutter mobile application. The platform is powered by Google Gemini 2.0 Flash to deliver smart, automated business insights.

---

## Repository Structure

```
SalesCRM/
├── backend/               # Django REST Framework Backend
├── mobile_app/            # Flutter Mobile Application
├── README.md              # This file
├── features_document.md   # Testing team features & navigation guide
└── features_document.docx # Testing team features guide (Word Format)
```

---

## Features Overview

### 1. Sales CRM Core
- **Contacts Management:** Detailed contact registry (designation, business details) with searchable List and Card views.
- **Customers Directory:** Directory of Individual and Company clients, detailing general metrics and linked opportunities.
- **Opportunity Management:** Opportunities board supporting list view, stage-priority filters, and a drag-and-drop interactive Kanban view.
- **Quotations (Read-Only):** Secure, view-only quotations overview for clients and sales agents.
- **Sales Orders:** Elaborate Sales Order display indicating delivery status, item counts, totals, reference quotes, and dates.

### 2. Receivables & Accounts Receivable Ageing
- **Invoices Tracker:** Manage and draft client invoices with status filters (Paid, Sent, Overdue, Cancelled).
- **AR Ageing:** Interactive summary categorized by aging brackets (Current, 1–30 Days, 31–60 Days, 61–90 Days, >90 Days Overdue).

### 3. System Administration
- **Roles:** Configure user roles and system security.
- **Subsidiaries:** Setup tax registrations, currencies, and subsidiary companies.

### 4. Advanced AI Features (Gemini 2.0 Flash)
- **Stalled Deal Detection:** Automatic scanning of opportunity duration and interaction frequency to flag stalled deals.
- **AI Lead Scoring:** Evaluates win probability (0–100) with detailed reasoning and confidence scoring based on notes.
- **Activity Log Analysis:** Processes unstructured activity logs to extract client sentiment, identify risk flags, and list action items.
- **Meeting Preparation:** Tailors strategic meeting talking points by digesting past client communications.
- **AI Methodology Dialog:** Every AI feature has an inline "How AI did this?" explanation button describing the data parsed and the LLM execution logic.

---

## Technical Guides

Detailed specifications and navigation coordinates for testing teams are saved at the root of the project:
* **Markdown Format:** [features_document.md](file:///d:/Projects/SalesCRM/features_document.md)
* **Word Document:** [features_document.docx](file:///d:/Projects/SalesCRM/features_document.docx)

---

## Getting Started: Backend (Django)

### Configuration
Update the configuration in the backend environment file [backend/.env](file:///d:/Projects/SalesCRM/backend/.env):
```env
# Gemini API Key configuration
GEMINI_API_KEY=<YOUR_GEMINI_API_KEY>

# Offline testing toggle (True to bypass actual Google billing constraints)
USE_MOCK_AI=True
```

### Installation & Run
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Activate the python virtual environment:
   ```bash
   # Windows:
   venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run migrations:
   ```bash
   python manage.py migrate
   ```
5. Launch backend server:
   ```bash
   python manage.py runserver
   ```

---

## Getting Started: Mobile App (Flutter)

### Installation & Execution
1. Navigate to the mobile app directory:
   ```bash
   cd mobile_app
   ```
2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the app in debug mode on a connected device/emulator:
   ```bash
   flutter run
   ```

### Compile Release Build (APK)
To compile a signed release APK for deployment or staging testing:
```bash
flutter build apk --release
```
The output APK file will be written to:
* **Path:** [app-release.apk](file:///d:/Projects/SalesCRM/mobile_app/build/app/outputs/flutter-apk/app-release.apk)
* **Folder:** `mobile_app/build/app/outputs/flutter-apk/`
