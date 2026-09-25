# Graasp Admin

Admin tooling for the Graasp platform, plus server-rendered Graasp apps (currently the Chatbot) embedded in the platform via iframe.

## Language

### Graasp apps

**Teacher**:
A member with admin permission on the item, viewing it in the builder. Everyone else is a student, including members with write permission.
_Avoid_: admin, builder

### Chatbot app

**Chatbot Settings**:
The teacher's configuration of a chatbot item: its name, system prompt, cue, starter suggestions and avatar. One per item.
_Avoid_: prompt settings, chatbot config

**Cue**:
The optional opening message the chatbot shows at the start of a new conversation. When the teacher leaves it empty, there is no cue.
_Avoid_: conversation starter, greeting

**Starter Suggestion**:
A ready-made student message offered as a one-click button on a new conversation.
_Avoid_: suggestion, quick reply

**System Prompt**:
The teacher's instructions sent to the model ahead of every conversation.
_Avoid_: initial prompt
