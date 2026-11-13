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

### Member storage

**Member**:
A Graasp account of type individual: a person with an email who can create items. Distinct from an admin user of this app.
_Avoid_: user (reserved for admin users), account (also covers guests)

**Storage Usage**:
The total size of the files a Member created. Only files count.
_Avoid_: quota, used space

**Default Storage Limit**:
The maximum Storage Usage for every Member without a Storage Limit Override.
_Avoid_: max storage, quota

**Storage Limit Override**:
A Member-specific limit set by an admin, above or below the default. Removing it puts the Member back on the Default Storage Limit. A limit below the current Storage Usage only blocks new uploads; nothing is deleted.
_Avoid_: custom quota, storage plan

**Effective Storage Limit**:
The limit that applies to a Member: their Storage Limit Override if they have one, otherwise the Default Storage Limit. It is what the Member sees in their account, without being told whether it is an override.
_Avoid_: max storage

### Item permissions

**Item Membership**:
A permission (read, write or admin, in increasing order) granted to an account on an item. It applies to the item and everything below it. A membership below another one for the same account only ever raises the permission.
_Avoid_: share, access, role

**Effective Permission**:
The highest permission an account holds on an item through Item Memberships on the item or its ancestors. An account without any has no Effective Permission, even on a public item.
_Avoid_: access level, role

**Hidden Item**:
An item that is hidden, or sits below a hidden item. Readers and visitors of a public item can't see it; accounts with write or admin can.
_Avoid_: private item (privacy is about memberships, not hiding)

### Public folder export

**Public Folder**:
A folder that is publicly visible: it, or one of its ancestors, carries the public tag. Anyone can browse it without logging in.
_Avoid_: shared folder, published folder (publishing is a separate library concept)

**Folder Export**:
A zip of a Public Folder's contents requested by a visitor, built in the background and kept for 24 hours. It uses the same raw layout as the logged-in export (files, documents, links), without the Graasp manifest.
_Avoid_: download, archive

**Exportable Content**:
What makes a Folder Export worth building: at least one file, document, link or description. Empty folders alone do not count.
_Avoid_: items (a description counts even though it is not an item)

**Visitor**:
A person without a login using a Public Folder. A Visitor has no email, so they follow a Folder Export on its progress page instead of being emailed.
_Avoid_: anonymous user, public user

**Export Progress Page**:
The page, reached by an unguessable link, where a Visitor watches a Folder Export advance and then gets its download link. It shows an expired state once the 24 hours are over.
_Avoid_: status page

### Core migration

**Core Route**:
One method and path template of core's API (`GET /api/items/:id`), as listed in the core inventory. Clients keep calling it unchanged throughout the migration.
_Avoid_: endpoint, API

**Ported Route**:
A Core Route that admin serves itself, with the same contract as core.
_Avoid_: migrated route, new route

**Proxied Route**:
A Core Route that admin forwards to core untouched, because it isn't ported yet or a Route Override sends it back.
_Avoid_: legacy route, passthrough

**Route Override**:
A switch an admin flips to send a Ported Route back to core, without a deploy, while a problem is fixed.
_Avoid_: feature flag, kill switch

**Actor**:
The account a Ported Route request acts for: a Member or a guest, identified by core's session cookie. Item operations are authorized against the Actor. A request without a valid session has no Actor. Distinct from an admin user.
_Avoid_: current user, scope (reserved for admin users), caller

**App Token**:
A short-lived grant core hands to an app running in an iframe, for one app item and one registered app origin. It may name an account, or none for an anonymous viewer of a public app. It only reaches that app item's own resources (app data, app settings, app actions), never items in general. Not an Actor.
_Avoid_: app JWT, guest token
