# QR Code-Based Industrial Asset Tracking System

## Project Structure

This project is a monorepo containing:

- `apps/mobile`: Flutter mobile application.
- `apps/web`: Flutter web application.
- `packages/`: Shared Dart packages (Core, Data, Features).
- `backend/`: Node.js backend API.

## Setup

1.  **Flutter:**
    Run `flutter pub get` in the root (if using Melos) or in each project directory.

2.  **Backend:**
    Navigate to `backend/` and run `npm install`.

## Development

- Use `melos` to manage the Flutter workspace.
- Backend runs on `npm run dev`.
