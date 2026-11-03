# Clean Connect

Clean Connect is a Flutter application for reporting and coordinating campus
sanitation requests. Students can report issues and track their status, staff
can claim and complete requests, and administrators can manage users, requests,
and facilities.

## Run the application

1. Configure Firebase for the target platforms and update
   `lib/firebase_options.dart` with the generated Firebase options.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Create the Firestore collections described below and deploy security rules
   that restrict user, staff, and administrator operations to the correct
   roles. Client-side role checks are not a substitute for Firestore rules.
4. Run `flutter pub get`, then `flutter run`.

## Firestore data

- `users/{uid}`: `uid`, `fullName`, `email`, `role` (`student`, `staff`, or
  `admin`), and `isActive`. New registrations receive the `student` role.
- `facilities/{facilityId}`: `facilityId`, `roomName`, `floor` (1–3),
  `roomType`, and `isActive`.
- `requests/{requestId}`: `reportedBy`, `facilityId`, `floor`, `issueType`,
  `description`, `status` (`pending`, `in_progress`, `completed`, or
  `cancelled`), `assignedTo`, `createdAt`, `acceptedAt`, and `completedAt`.

The application creates a student profile after email registration and creates
a default student profile for an authenticated account that does not yet have a
Firestore profile. Grant administrator access only through trusted
administrative tooling.
