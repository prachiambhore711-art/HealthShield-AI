# HealthShield AI Project Rules & Development Guidelines

Welcome to **HealthShield AI** ("Your Health, Your Shield"). This document defines the permanent development rules, architecture principles, design guidelines, security constraints, and technology decisions for the application.

> [!IMPORTANT]
> All developers and AI coding agents must read and strictly adhere to these rules before making any design, coding, or configuration changes.

---

## 1. Project Overview & Vision

HealthShield AI is an Android mobile healthcare application designed to serve as a complete digital health companion with emergency capabilities. It provides everyday health utility while solving the critical issue of emergency medical-information retrieval when a patient is unconscious or unable to communicate.

### Key Capabilities
- **Secure Emergency QR**: A secure access mechanism for medical professionals and emergency helpers to retrieve patient-critical data.
- **Secure Health Profiles**: Detailed profile containing blood group, allergies, conditions, surgeries, and medications.
- **Role-Based Access Control**: Experiences tailored to Patients/Users and Doctors.
- **Emergency Contacts**: Quick access to contact information and instant calling features for trusted individuals.
- **Medical Report Storage**: Ability to upload, store, and view prescriptions, lab reports, X-rays, etc.
- **Health Reminders**: Medication and profile update reminders for daily utility.
- **AI Health Education Assistant**: A helper to understand medical reports and health concepts without diagnosing or prescribing.
- **Location-Based Doctor Suggestions**: Suggest nearby doctors/facilities using location services rather than predicting diseases.
- **Access Logging**: Audit trails tracking who accessed a patient's medical information, when, and what level of data was returned.

---

## 2. Technology Stack & Directory Constraints

- **Frontend**: Flutter (Dart) targeting Android.
  - Prioritize clean architecture, reusable widgets, responsive layout, and consistent themes.
- **Backend**: FastAPI (Python).
  - REST APIs designed to support feature development in vertical slices.
- **Database**: SQLite.
  - Used for storing users/patients, doctors, profiles, medical reports metadata, QR tokens, reminders, access logs, and verification status.
- **AI Integration**: Abstract API calls (e.g., Gemini, OpenAI) wrapped in services so that underlying providers can be easily swapped.

---

## 3. Architecture & Security Principles

### Core User Model
- **Unified Patient/User Model**: Every registered person in the system is treated as a Patient/User. There is no separate "ordinary" or "public" user model required for the core architecture. Every user has a patient profile (including blood group, emergency contacts, reminders, etc.) whether they currently have active medical conditions/reports or not.

### Unconscious Patient Emergency Access
- **No Personal Authentication Requirement**: Emergency access must NOT depend on the patient's ability to enter a PIN, scan a fingerprint, use face unlock, or unlock their phone.
- **Separation of Concerns**: The Emergency QR/access mechanism must be designed completely independently from the patient's private dashboard authentication.

### Secure Emergency QR Design
- **No Direct Medical Profiles**: The QR code must NEVER encode the patient's actual medical profile.
- **Reference / Token System**: The QR code stores only a secure, non-sensitive reference token.
  $$\text{Scan QR} \rightarrow \text{Retrieve Secure Token} \rightarrow \text{Backend API} \rightarrow \text{Authorize Requestor} \rightarrow \text{Return Permitted Data}$$
- **Same QR, Different Scanning Access**: The *exact same* physical QR code is scanned by both general emergency helpers and verified doctors. The backend determines the returned information based on the scanner's authenticated status and authorization.
- **QR Security (Revocation & Regeneration)**: Patients must be able to revoke and regenerate their emergency QR. Once revoked, the previous QR token must be immediately invalidated and no longer provide access.
- **QR & API Abuse Protection**: Emergency QR endpoints and sensitive APIs must have basic rate limiting and abuse protection based on both QR/token usage and request source/IP where practical. Keep the implementation lightweight and suitable for a college mini-project.

### Access Levels for QR Scanning (Least Privilege)
1. **General/Unverified Emergency Access (Public Scanner)**:
   - Returns ONLY: Patient first name, blood group, emergency contact information, and a call/contact action.
   - Must **NOT** return allergies, diseases, medications, surgeries, medical reports, or other private medical information.
2. **Verified Doctor Access (Authenticated and Verified Scanner)**:
   - Returns: First name, blood group, allergies, diseases/conditions, current medications, previous surgeries, and permitted medical reports.

### Doctor Role & Verification
- **No Automatic Privilege**: Selecting "Doctor" during registration must NOT automatically grant doctor privileges.
- **Simple Backend Verification**: Newly registered doctors start with a `Pending` status. Admin/backend verification updates this to `Verified Doctor`, granting them search/scanning privileges. Real-world medical licensing verification systems are out of scope.

### App-Level Security (Patient Private Dashboard)
- **Dashboard Authentication**: Opening the application must not automatically expose the patient's private medical history simply because the phone itself is unlocked.
- **Access Authentication**: Private dashboard access requires app-level authentication. Support both a user-defined app PIN and device biometric authentication (fingerprint/face unlock). The PIN must remain available as a fallback when biometrics are unavailable or fail.

### Data Persistence & Recovery
- **Backend/Cloud Storage**: Important patient data must be synchronized and stored through the backend database and must not depend exclusively on the patient's physical phone. This allows the patient to recover and access their account from another device if their phone is lost, damaged, or replaced.

### Access Logging
- **Required Logging**: Every emergency QR access attempt must be logged.
- **Verified Doctor Log Schema**: Record the doctor's identity (ID/Name), timestamp, accessed patient reference (token), access result (success/failure), and access level.
- **General Emergency Log Schema**: Record the access as anonymous/general emergency access with timestamp, token/reference, and access result.
- **Data Minimization**: Do not store unnecessary sensitive medical details in the access logs.

---

## 4. UI/UX & Design Guidelines

The application must feel modern, premium, trustworthy, and healthcare-focused. Avoid clinical, cold, or overly complex designs.

### Visual Themes & Color Palette
- **Primary Color**: Professional / deep blue.
- **Secondary Color**: Teal.
- **Background**: White / very light blue.
- **Text**: Dark navy / charcoal.
- **Emergency Accent**: Red (reserved strictly for emergency alerts or actions; must NOT dominate the interface).
- **Success Accent**: Green.
- **Warning Accent**: Amber / orange.

### Design Patterns
- **Rounded Cards & Spacing**: Use clean spacing and cards with consistent corner radii to divide information blocks.
- **Modern Typography**: Use clean typography from Google Fonts with correct line-height, letter-spacing, and hierarchy.
- **Iconography and Illustrations**: Use high-quality icons and selective illustrations (e.g., for onboarding and empty states). Avoid excessive, random stock photographs.
- **Dynamic Responsiveness**: All layouts and component dimensions must adjust smoothly to different screen sizes without shifting content layout.

---

## 5. AI Health Assistant Guidelines

- **Educational & Support Role Only**: The AI feature is an educational/support assistant. It must NOT diagnose diseases or prescribe specific medications.
- **Approved Tasks**: The assistant may explain general medical concepts, help users understand reports in an educational manner, provide health reminders, offer general wellness guidance, and encourage professional consultation.
- **Application Interface**: The HealthShield AI interface must remain inside our application (no redirects to external ChatGPT/Gemini websites).
- **Abuse & Provider Abstraction**: Gemini is the initial AI provider. The integration must be hidden behind an abstraction/service layer so that the provider can be replaced later without redesigning the application code.

---

## 6. Coding Conventions & Best Practices

- **Feasibility & Simplicity**: Keep the architecture simple and feasible for a college mini-project. Do not introduce unnecessary enterprise-level technologies or complexity.
- **Feature Vertical Slices**: Build features from start to finish as full vertical slices:
  $$\text{UI} \rightarrow \text{API Signature} \rightarrow \text{Backend Service} \rightarrow \text{Database Schema} \rightarrow \text{Auth/Authz} \rightarrow \text{Testing}$$
- **Maintain Code Integrity**: Keep existing comments, docstrings, and helper functions intact.
- **Clean Code & Reusability**: Do not duplicate styling rules, colors, or business logic. Reuse established constants, services, models, and UI widgets.
