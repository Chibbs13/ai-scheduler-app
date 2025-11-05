from flask import Flask, request, jsonify
from flask_cors import CORS
import openai
import os
from dotenv import load_dotenv
import json
import datetime

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Get API key with validation
api_key = os.getenv('OPENAI_API_KEY')
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable is not set. Please check your .env file.")

# Initialize OpenAI client
openai.api_key = api_key

# System message that defines the AI assistant's role and capabilities
SYSTEM_MESSAGE = """You are an AI assistant for a todo application. Your role is to help users manage their tasks and schedule effectively. You can:
1. Help create and organize todos
2. Provide scheduling suggestions
3. Help prioritize tasks
4. Give productivity tips
5. Help break down complex tasks
6. Suggest task categories and tags

Always be concise, practical, and focused on helping users manage their tasks better."""

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        user_message = data.get('message')
        context = data.get('context', {})  # Get additional context if provided
        
        if not user_message:
            return jsonify({'error': 'Message is required'}), 400

        # Prepare the conversation history
        messages = [
            {"role": "system", "content": SYSTEM_MESSAGE}
        ]

        # Add context if available
        if context:
            context_message = f"Current context: {json.dumps(context)}"
            messages.append({"role": "system", "content": context_message})

        # Add the user's message
        messages.append({"role": "user", "content": user_message})

        # Call OpenAI API
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=messages,
            temperature=0.7,
            max_tokens=250,
            presence_penalty=0.6,
            frequency_penalty=0.3
        )

        # Extract the assistant's response
        assistant_message = response.choices[0].message.content

        return jsonify({
            'response': assistant_message,
            'model': response.model,
            'usage': {
                'prompt_tokens': response.usage.prompt_tokens,
                'completion_tokens': response.usage.completion_tokens,
                'total_tokens': response.usage.total_tokens
            }
        })

    except Exception as e:
        error_message = str(e)
        if "API key" in error_message:
            return jsonify({'error': 'Invalid API key configuration'}), 401
        elif "rate limit" in error_message.lower():
            return jsonify({'error': 'Rate limit exceeded. Please try again later.'}), 429
        else:
            return jsonify({'error': 'An error occurred while processing your request'}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'service': 'todo-ai-assistant',
        'version': '1.0.0'
    })

@app.route('/api/ai-tasks', methods=['POST'])
def ai_tasks():
    data = request.json
    user_message = data.get('message', '')

    today = datetime.date.today().isoformat()
    prompt = f'''
You are a task extraction assistant.
Given a message, extract ALL individual task instances as a JSON array.
If the message describes a recurring task (e.g., "every Monday and Wednesday at 7:30pm for a week"),
expand it into a separate object for each occurrence, with the correct date and time for each.
If multiple days are specified (e.g., every Monday and Wednesday), expand into a separate object for each occurrence on each day.
If the message contains multiple different tasks, extract and expand each one as described above.
Each object should have: Task (the task description), Date (YYYY-MM-DD), Time (HH:MM), and Duration (if present).
For each task, extract the actual values from the message. Do not use null, empty, or placeholder values.

Always use the next upcoming dates based on today's date ({today}).
If the month or year is not specified, use the current month and year.
If the message contains more than 5 unique tasks, only return the first 5 unique tasks (by task description), but include all their recurrences.

Good Example input: "Remind me to take out the trash every Monday at 7:30pm for a month, call mom every Wednesday at 5pm for a month, study math every Tuesday at 4pm for a month, go to the gym every Friday at 6am for a month, walk the dog every Saturday at 8am for a month, and read a book every Sunday at 9pm for a month"
Good Example output: [
  {{"Task": "take out the trash", ...}},
  {{"Task": "call mom", ...}},
  {{"Task": "study math", ...}},
  {{"Task": "go to the gym", ...}},
  {{"Task": "walk the dog", ...}}
  // No "read a book" tasks included, since that's the 6th unique task
]

Bad Example output: [
  {{"Task": null, "Date": null, "Time": null, "Duration": null}}
]

Message: "{user_message}"

ONLY return the JSON array. Do not use null, empty, or placeholder values.
'''

    response = openai.ChatCompletion.create(
        model="gpt-4-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant that extracts tasks from user messages and returns them as a JSON array."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=2048,
        temperature=0.2,
    )
    text = response.choices[0].message.content.strip()
    print("AI raw response:", text)  # Debug print
    # Try to extract JSON from the response
    try:
        json_start = text.index('[')
        json_end = text.rindex(']')
        json_string = text[json_start:json_end+1]
        tasks = json.loads(json_string)
    except Exception as e:
        return jsonify({'error': 'Failed to parse tasks', 'raw': text}), 400

    return jsonify({'tasks': tasks})

if __name__ == '__main__':
    app.run(debug=True, port=5000) 