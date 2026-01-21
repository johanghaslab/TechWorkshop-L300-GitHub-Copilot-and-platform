---
title: "Add chat feature with Microsoft Foundry Phi4 integration"
labels: [enhancement, chat, foundry, phi4]
assignees: []
---

## Feature: Chat Page with Microsoft Foundry Phi4 Integration

### Description
Add a new chat page to the application that allows users to send messages to a Microsoft Foundry Phi4 endpoint and display the AI's response in a text area. The chat feature is implemented as a separate page and is configurable via `appsettings.json`.

### Implementation Details
- New `ChatController` and `Views/Chat/Index.cshtml` for the chat UI and logic.
- User messages are sent to the configured Foundry Phi4 endpoint (update the endpoint URL in `appsettings.json` as needed).
- Responses are appended to the chat area in real time.
- All code builds and integrates with the existing .NET MVC structure.

### Acceptance Criteria
- [ ] Chat page is accessible and functional.
- [ ] Messages are sent to the Foundry Phi4 endpoint and responses are displayed.
- [ ] Endpoint URL is configurable.
- [ ] No build errors.

### Additional Notes
- The endpoint URL is currently a placeholder. Update it for production use.
- See PR for code details and integration points.
