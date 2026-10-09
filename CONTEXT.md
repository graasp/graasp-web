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

**Context Document**:
A PDF the teacher uploads, whose extracted text is given to the model as reference material on every student message. Students don't see it. Up to 5 per item.
_Avoid_: source, attachment, context file

**Cue**:
The optional opening message the chatbot shows at the start of a new conversation. When the teacher leaves it empty, there is no cue.
_Avoid_: conversation starter, greeting

**Starter Suggestion**:
A ready-made student message offered as a one-click button on a new conversation.
_Avoid_: suggestion, quick reply

**System Prompt**:
The teacher's instructions sent to the model ahead of every conversation.
_Avoid_: initial prompt

### Public folder export

**Public Folder**:
A folder that is publicly visible: it, or one of its ancestors, carries the public tag. Anyone can browse it without logging in.
_Avoid_: shared folder, published folder (publishing is a separate library concept)

**Folder Export**:
A zip of a Public Folder's contents requested by a visitor, built in the background and kept for 24 hours. It uses the same raw layout as the logged-in export (files, documents, links), without the Graasp manifest.
_Avoid_: download, archive

**Visitor**:
A person without a login using a Public Folder. A Visitor has no email, so they follow a Folder Export on its progress page instead of being emailed.
_Avoid_: anonymous user, public user

**Export Progress Page**:
The page, reached by an unguessable link, where a Visitor watches a Folder Export advance and then gets its download link. It shows an expired state once the 24 hours are over.
_Avoid_: status page
