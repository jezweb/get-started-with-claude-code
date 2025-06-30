# Todo App - Example Project Brief

This is a filled-out example of how to use the PROJECT_BRIEF template for a simple todo app.

## App Overview

**App Name:** TaskMaster

**Purpose:** A simple, elegant todo app that helps users manage daily tasks efficiently.

**Target Audience:** Anyone who wants a straightforward way to track tasks without complexity.

## Core Features (MVP)

### Must Have:
1. **Add Tasks** - Quick input with Enter key support
2. **Complete Tasks** - Click to mark done with visual feedback
3. **Delete Tasks** - Remove unwanted tasks
4. **Persist Data** - Save tasks in browser storage
5. **Task Counter** - Show progress (3 of 5 completed)

### Nice to Have:
1. Categories/Tags
2. Due dates
3. Search functionality
4. Dark mode
5. Export tasks

## User Experience

### User Journey:
1. User opens app → sees clean interface
2. Types task → hits Enter → task appears
3. Clicks checkbox → task marked complete
4. Clicks delete → task removed
5. Refreshes page → tasks still there

### Design Principles:
- **Clean** - Minimal, distraction-free
- **Fast** - Instant feedback
- **Intuitive** - No instructions needed
- **Responsive** - Works on all devices

## Technical Approach

### Frontend:
- Pure HTML, CSS, JavaScript (no framework for MVP)
- LocalStorage for persistence
- CSS Grid/Flexbox for layout
- CSS animations for interactions

### Structure:
```
todo-app/
├── index.html      # Main structure
├── style.css       # Styling
├── script.js       # Functionality
└── README.md       # Instructions
```

### Key Considerations:
- Accessibility (keyboard navigation, ARIA labels)
- Mobile-first design
- Cross-browser compatibility
- No external dependencies for MVP

## Example Prompt to Claude

Based on this brief, here's what you'd tell Claude:

```
Create a todo app called TaskMaster based on this brief:
[paste the relevant sections above]

Start with the MVP features and make it work perfectly before adding anything else.
```

## Success Criteria

The app is ready when:
- [ ] Users can add tasks by typing and pressing Enter
- [ ] Tasks persist after page refresh
- [ ] Completed tasks show visual distinction
- [ ] Delete functionality works smoothly
- [ ] Counter shows X of Y tasks completed
- [ ] Works well on mobile and desktop
- [ ] Code is clean and commented

## Learning Goals

Building this app teaches:
- DOM manipulation
- Event handling
- LocalStorage API
- CSS transitions
- Responsive design
- State management basics

This example shows how a simple brief can guide Claude to build exactly what you want!