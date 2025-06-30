# Todo App - Example Prompt

This shows how to turn a project brief into an effective prompt for Claude Code.

## The Complete Prompt

```
Create a todo app called TaskMaster with these features:

MVP Requirements:
1. Clean, minimal interface with a header, input area, and task list
2. Add tasks by typing and pressing Enter (clear input after adding)
3. Mark tasks complete by clicking a checkbox (strikethrough text)
4. Delete tasks with a delete button (smooth fade out animation)
5. Show task counter: "3 of 5 tasks completed"
6. Save all tasks in localStorage (persist on refresh)

Design:
- Use a centered card layout (max-width: 600px)
- Soft shadows and rounded corners
- Color scheme: Blue accent (#4A90E2), light gray backgrounds
- Smooth transitions (0.3s) for all interactions
- Mobile responsive

Code Structure:
- index.html - semantic HTML5
- style.css - organized with comments
- script.js - clean, well-commented JavaScript

Make it production-ready with:
- Keyboard accessibility
- ARIA labels
- Error handling
- Empty state message
- Focus management

Please create all files and explain how to run it.
```

## What This Prompt Does Well

### 1. **Specific Requirements**
- Lists exact features needed
- Defines interaction details
- Specifies visual feedback

### 2. **Design Direction**
- Provides color scheme
- Mentions specific CSS features
- Sets responsive requirement

### 3. **Quality Standards**
- Asks for accessibility
- Requests error handling
- Wants production-ready code

### 4. **Clear Structure**
- Specifies file organization
- Asks for comments
- Sets code standards

## Alternative Prompts

### Beginner Version
```
Create a simple todo app where I can:
- Add tasks
- Check them off
- Delete them
- Have them save when I refresh

Make it look nice and modern. Keep it simple!
```

### Advanced Version
```
Build a TaskMaster todo app with:
- TypeScript
- Vue 3 composition API
- Tailwind CSS
- Vitest for testing
- PWA capabilities
- Drag-and-drop reordering
- Multiple lists
- Cloud sync ready

Include proper error boundaries, loading states, and offline support.
```

### Styling Focused
```
Create a todo app that looks like a physical notebook:
- Paper texture background
- Handwriting-style fonts
- Sketch-like checkboxes
- Torn paper effect for deletions
- Page flip animation for completed tasks
```

## Tips for Writing Prompts

### DO:
- ✅ Be specific about features
- ✅ Mention design preferences
- ✅ Ask for code organization
- ✅ Request explanations
- ✅ Specify any constraints

### DON'T:
- ❌ Be too vague ("make it good")
- ❌ Overwhelm with features
- ❌ Assume Claude knows your preferences
- ❌ Forget about mobile/accessibility
- ❌ Skip the "how to run it" part

## Iterating on Your App

After Claude creates the initial version, try these follow-ups:

```
Add a feature to categorize tasks as Work, Personal, or Shopping with different colors
```

```
Make it so I can edit tasks by double-clicking on them
```

```
Add a celebration animation when all tasks are completed
```

```
Create a dark mode that remembers my preference
```

## Remember

- Start simple, add complexity later
- Test each feature before adding more
- Ask Claude to explain anything unclear
- Save versions as you go
- Have fun building!

This example shows how a well-crafted prompt leads to exactly the app you want!