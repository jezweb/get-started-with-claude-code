# **AI Project Brief: [Project Name]**

## 1. The Vision

*   **Problem:** [Describe the current pain point or what's broken. What is the frustrating, slow, or expensive process that this project will fix?]
*   **Solution:** [Describe the project at a high level. How does it solve the problem in a new or better way? What is the core idea?]
*   **Users:** [Who is this for? Be specific. e.g., "Project managers," "Sales teams," "Small business owners."]

## 2. The North Star Feature (MVP)

> This is the one, non-negotiable feature that proves the core value of the app. It should be a complete end-to-end flow that you can demonstrate to a client and say, "This is what it does."

[Describe the single most important user journey for the Minimum Viable Product. e.g., "A user uploads a PDF and asks a question about it, and the AI gives a correct answer."]

## 3. The AI Core: How It Thinks

*   **The AI's Job:** [In plain English, what is the AI's specific role? Is it a researcher, a writer, a data analyst, a summarizer? What is its main function?]
*   **The "Brain" (RAG / Knowledge Base):** [How does the AI get its knowledge? Where does the information come from? Be specific.]
    *   *Examples: Vertex AI Search, a manual RAG setup using ChromaDB, a specific set of websites, a SQL database, etc.*
*   **The "Personality" (LLM):** [Which primary Large Language Model will we use for reasoning and generation?]
    *   *Examples: Gemini 2.5 Pro (via Vertex AI), Claude 4 Sonnet, etc.*
*   **The "Blueprint" (Initial System Prompt):** [This is the most important piece of 'code' for the AI. Write the first draft of the instructions that will give the AI its personality, rules, and purpose.]
    ```
    You are a [role]. You are [characteristic 1], [characteristic 2], and [characteristic 3].

    Your primary job is to [main function].

    RULES:
    1. Your knowledge is strictly limited to [source of information].
    2. If you don't know the answer, you must say "I cannot find an answer in the provided documents." Do not invent information.
    3. [Add another key rule, e.g., about output format].
    ```

## 4. How It Feels To Use It (User Narrative)

> Write a short story describing a perfect interaction from the user's point of view. This makes the abstract vision concrete.

[e.g., "A user logs in, navigates to their project, and types 'Summarize the key outcomes from the last client meeting.' The AI instantly provides three bullet points that correctly identify the action items from a meeting transcript they uploaded earlier."]

## 5. Tech Stack

| Component | Technology | Why? (Keep it brief) |
| :--- | :--- | :--- |
| **Frontend** | [e.g., Vue.js, React] | [e.g., Team familiarity, performance] |
| **Backend** | [e.g., Python with FastAPI] | [e.g., AI ecosystem, performance] |
| **Database** | [e.g., SQLite, PostgreSQL] | [e.g., Simplicity for MVP, scalability] |
| **AI Orchestration** | [e.g., LangChain] | [e.g., Provides structure for AI chains] |
| **AI Core** | [e.g., Vertex AI, Hugging Face] | [e.g., Scalability, managed service] |

## 6. User Stories (MVP)

> List only the essential stories needed to build the "North Star Feature."
> Format: As a [type of user], I want to [action] so that [benefit].

*   As a user, I want to...
*   As a user, I want to...
*   As a user, I want to...

## 7. Progress Tracker

### Done ✅
-   [x] Project vision defined and agreed upon.
-   [x] Initial project brief created.

### Doing 🚧
-   [ ] [Current feature being built]
-   [ ] [Testing/debugging what]

### Next 📋
-   [ ] [Next priority feature]
-   [ ] [Following feature]

## 8. Decisions Made

| Decision | Why | When |
| :--- | :--- | :--- |
| Chose [X] | Because [reason] | [Date] |
| Avoided [Y] | Due to [reason] | [Date] |

## 9. Questions / Blockers

> What are we unsure about? What's stopping us?

*   [ ] [e.g., How should we handle X?]
*   [ ] [e.g., Need to research the best way to do Y.]

## 10. Success Metrics

> How will we know we've won? What can we measure?

*   **Speed:** [e.g., Average response time is under X seconds.]
*   **Accuracy:** [e.g., The AI provides a factually correct answer in X% of test cases.]
*   **User Adoption:** [e.g., X users actively using the feature within the first month.]

## 11. Resources & References

*   [Link to similar app or inspiration]: [What we like about it]
*   [Link to key documentation]: [e.g., API docs for a service we're using]
*   [Link to helpful tutorial/article]:
