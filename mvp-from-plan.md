# Build MVP from Existing Plan

Use this when you already have a PRD, design doc, or detailed plan from elsewhere.

## The Prompt

```
[insert the @ file name and project name first]

This is project brief to create an MVP using a test-driven approach. 

You have access to MCP servers:
- context7 for looking up coding documentation
- playwright for e2e testing

As you work, create any documents you think would be helpful, such as:
- Planning doc with TDD/BDD approach
- Project structure and requirements
- Backend API design (FastAPI or similar)
- Frontend component structure
- Test strategy and coverage goals

You can use todo, scratchpad, jupyter and md files as you need to for planning, tracking and managing the project.

Please:
1. Use a test-first approach - write tests before implementation
2. Add proper validation on both frontend and backend
3. Look up current package versions and check docs when integrating dependencies
4. Create or ask for sample data/inputs as needed
5. Include comprehensive error handling
6. Provide clear scripts to start the application
7. If using Python, create a virtual environment first
8. Use high port numbers (20000+) picked randomly to avoid conflicts
9. Keep the dev server running so I can monitor progress

After the MVP is working, suggest enhancements and improvements we could add.

Let's build this systematically. Think about all the details.
```

## Tips for Best Results

### What to Include in Your Plan:
- **Core Features** - What must the MVP do?
- **User Stories** - Who uses it and how?
- **Technical Constraints** - Any specific requirements?
- **UI/UX Notes** - Design preferences or examples
- **Data Model** - Key entities and relationships

### What Claude Will Do:
- Analyze your requirements
- Create appropriate documentation
- Set up testing framework
- Build features test-first
- Validate all inputs
- Handle errors gracefully
- Provide running instructions
- Suggest next steps

## Example Usage

### SaaS Application
```
I have a detailed plan for a subscription management system:

- Users can sign up and manage subscriptions
- Admin dashboard for monitoring
- Stripe integration for payments
- Email notifications
- Usage tracking and limits

[Rest of PRD details...]

Now create the MVP using a test-driven approach...
```

### API Service
```
I have a detailed plan for a weather data API:

- RESTful endpoints for weather data
- Authentication with API keys
- Rate limiting per user
- Cache responses for efficiency
- Support multiple data formats

[Rest of specifications...]

Now create the MVP using a test-driven approach...
```

### Full-Stack Application
```
I have a detailed plan for a project management tool:

Features:
- Kanban board interface
- Real-time collaboration
- Task assignments and due dates
- File attachments
- Activity timeline
- Email notifications

Technical requirements:
- React frontend
- FastAPI backend
- PostgreSQL database
- WebSocket for real-time updates
- JWT authentication

[Additional details...]

Now create the MVP using a test-driven approach...
```

## What to Expect

Claude will typically:
1. Review your requirements
2. Create planning documents as needed
3. Set up project structure
4. Configure testing framework
5. Build features incrementally with tests
6. Add validation and error handling
7. Create startup scripts
8. Test everything works together
9. Suggest improvements

## Remember

- Be specific in your plan
- Include acceptance criteria
- Mention any preferred technologies
- Describe the target users
- Note any constraints or limitations

The more detail you provide, the better Claude can build exactly what you need.
