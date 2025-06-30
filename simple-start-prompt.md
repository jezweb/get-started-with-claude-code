# 🎯 Simple Start Prompt - Build a Todo App

This prompt will help you build a complete todo app with Claude Code. Just copy and paste it!

## The Prompt

Copy this entire prompt and paste it into Claude Code:

```
Create a todo app that:
- Lets users add new tasks
- Mark tasks as complete
- Delete tasks
- Shows completed tasks with strikethrough
- Saves tasks in browser localStorage
- Has a clean, modern design

Use HTML, CSS, and JavaScript. No frameworks needed.

Make it look professional with:
- A centered container
- Nice colors and spacing
- Smooth transitions
- Mobile-friendly design

Include these features:
1. Input field with "Add" button
2. List showing all tasks
3. Checkbox to mark complete
4. Delete button for each task
5. Counter showing total and completed tasks

Please create all files and explain how to run it.
```

## What Claude Will Do

1. **Create index.html** - The app structure
2. **Create style.css** - Make it look good
3. **Create script.js** - Add functionality
4. **Explain the code** - Help you understand
5. **Show you how to run it** - Get started quickly

![Todo app with no tasks](images/browser/todo-app-empty.png)

Once you add some tasks, it will look like this:

![Todo app with tasks](images/browser/todo-app-with-tasks.png)

## After Claude Creates Your App

### Try These Improvements

Ask Claude to add any of these features:

1. **Categories**
   ```
   Add categories to tasks (Work, Personal, Shopping)
   with different colors for each category
   ```
   
   ![Todo app with categories](images/examples/todo-app-categories.png)

2. **Due Dates**
   ```
   Add due dates to tasks and highlight overdue items
   ```

3. **Search**
   ```
   Add a search box to filter tasks
   ```

4. **Dark Mode**
   ```
   Add a dark mode toggle
   ```
   
   ![Todo app with dark mode](images/examples/todo-app-dark-mode.png)

5. **Export/Import**
   ```
   Add buttons to export tasks to a file and import them back
   ```

## Learning Tips

### Understand the Code
Ask Claude:
- "Explain how the localStorage part works"
- "Walk me through the event listeners"
- "How does the CSS make it responsive?"

### Make It Yours
- Change colors and fonts
- Add your own features
- Experiment with the design

### Common Modifications

1. **Change the Style**
   ```
   Make it look like a sticky note board
   ```

2. **Add Animations**
   ```
   Add smooth animations when tasks are added or removed
   ```

3. **Add Sounds**
   ```
   Play a sound when completing tasks
   ```

## Troubleshooting

### App Not Working?
- Make sure all files are in the same folder
- Open index.html in a web browser
- Check the browser console for errors (F12)

### Want to Start Over?
```
Let's start fresh. Create a new todo app with a different design
```

### Need Help Understanding?
```
Can you explain this part: [paste code snippet]
```

## Next Steps

### Ready for More?
1. Try adding a feature from the list above
2. Build something different (calculator, timer, notes app)
3. Check out [examples/](examples/) for more ideas

### Want to Use a Framework?
Once comfortable with vanilla JavaScript, ask Claude:
```
Convert this todo app to use Vue 3 and Vite
```

## Pro Tips

- **Save your work**: Create a GitHub repository
- **Share it**: Deploy to GitHub Pages or Netlify
- **Keep learning**: Each project teaches something new

Happy building! 🚀