# Core routes

Generated from core at [`98fa66853`](https://github.com/graasp/graasp/tree/98fa6685304bf03476e569c53605b6f8d09a6793) by `scripts/regenerate.sh`. Do not edit by hand.

178 routes in 49 modules. Swagger UI and the DEV-only queue dashboard are left out.

**Auth:** `session` = session cookie required · `optional` = session used if present · `validated` = member with a validated email · `member` = a member, not a guest · `guest` = item-login guest · `app JWT` = token given to an app iframe · **none** = no check.

**Reads** leaves out tables the route also writes. Almost every item route reads `account`, `item`, `item_membership` and `item_visibility` for the permission check.

**Calls** are the service methods the handler calls directly, a starting point for the spec. **Hooks** are service hooks fired along the way that have handlers registered.

## Summary

| Module | Routes | No auth | Writes DB | WS | Email | Job | Storage | Search | External |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| [auth/magicLink](#authmagiclink) | 4 | 1 | 3 |  | 2 |  |  |  | 2 |
| [auth/password](#authpassword) | 6 |  | 5 |  | 1 |  |  |  | 3 |
| [chat](#chat) | 5 |  | 4 | 4 | 1 |  |  |  |  |
| [chat/mentions](#chatmentions) | 4 |  | 3 |  |  |  |  |  |  |
| [item](#item) | 12 |  | 7 | 3 |  | 5 | 8 | 5 | 2 |
| [item/action](#itemaction) | 5 |  | 2 | 1 | 1 |  | 1 |  |  |
| [item/app](#itemapp) | 6 | 1 | 2 |  |  | 2 | 1 | 2 |  |
| [item/app/appAction](#itemappappaction) | 2 |  | 1 | 1 |  |  |  |  |  |
| [item/app/appData](#itemappappdata) | 6 |  | 4 | 3 |  |  | 3 |  |  |
| [item/app/appSetting](#itemappappsetting) | 4 |  | 3 | 3 |  |  | 1 |  |  |
| [item/app/appSetting/file](#itemappappsettingfile) | 2 |  | 1 |  |  |  | 2 |  |  |
| [item/app/chatBot](#itemappchatbot) | 1 |  |  |  |  |  |  |  | 1 |
| [item/capsule](#itemcapsule) | 2 |  | 2 |  |  | 2 | 1 | 2 |  |
| [item/document](#itemdocument) | 2 |  | 2 |  |  | 2 | 1 | 2 |  |
| [item/embeddedLink](#itemembeddedlink) | 3 |  | 2 |  |  | 2 | 1 | 2 | 3 |
| [item/enroll](#itemenroll) | 1 |  | 1 |  |  |  |  |  |  |
| [item/etherpad](#itemetherpad) | 3 |  | 2 |  |  | 2 | 1 | 2 | 2 |
| [item/file](#itemfile) | 3 |  | 2 |  |  | 2 | 2 | 2 |  |
| [item/folder](#itemfolder) | 4 |  | 4 |  |  | 4 | 2 | 4 |  |
| [item/geolocation](#itemgeolocation) | 6 |  | 2 |  |  |  | 2 |  | 2 |
| [item/html/h5p](#itemhtmlh5p) | 1 |  | 1 |  |  | 1 | 1 | 1 |  |
| [item/importExport](#itemimportexport) | 4 |  | 2 |  |  | 2 | 3 | 1 | 2 |
| [item/invitation](#iteminvitation) | 8 |  | 5 | 3 | 4 | 1 | 1 | 1 | 1 |
| [item/itemBookmark](#itemitembookmark) | 3 |  | 2 |  |  |  | 1 |  |  |
| [item/itemFlag](#itemitemflag) | 2 | 1 | 1 |  |  |  |  |  |  |
| [item/itemLike](#itemitemlike) | 4 |  | 2 |  |  |  |  | 2 |  |
| [item/itemVisibility](#itemitemvisibility) | 2 |  | 2 |  |  |  |  |  |  |
| [item/page](#itempage) | 3 |  | 3 |  |  | 1 | 1 | 1 |  |
| [item/publication/publicationState](#itempublicationpublicationstate) | 1 |  |  |  |  |  |  |  | 1 |
| [item/publication/published](#itempublicationpublished) | 4 |  | 2 |  | 1 | 2 | 1 | 2 | 1 |
| [item/publication/published/search](#itempublicationpublishedsearch) | 6 |  | 1 |  |  | 1 | 4 | 5 |  |
| [item/publication/validation](#itempublicationvalidation) | 2 |  | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| [item/recycled](#itemrecycled) | 3 |  | 2 | 2 |  |  |  |  |  |
| [item/shortLink](#itemshortlink) | 6 | 2 | 3 |  |  |  |  |  |  |
| [item/shortcut](#itemshortcut) | 2 |  | 2 |  |  | 2 | 1 | 2 |  |
| [item/tag](#itemtag) | 3 |  | 2 |  |  | 2 |  | 2 |  |
| [item/thumbnail](#itemthumbnail) | 3 |  | 2 |  |  | 2 | 3 | 2 |  |
| [itemLogin](#itemlogin) | 5 |  | 3 |  |  |  |  |  |  |
| [itemMembership](#itemmembership) | 4 |  | 3 | 3 | 1 |  |  |  |  |
| [itemMembership/MembershipRequest](#itemmembershipmembershiprequest) | 4 |  | 2 |  | 1 |  |  |  |  |
| [maintenance](#maintenance) | 1 | 1 |  |  |  |  |  |  |  |
| [member](#member) | 11 |  | 5 |  | 2 |  |  |  |  |
| [member/action](#memberaction) | 2 |  | 1 |  |  |  |  |  |  |
| [member/export-data](#memberexport-data) | 1 |  |  |  | 1 |  | 1 |  |  |
| [member/profile](#memberprofile) | 4 |  | 2 |  |  |  |  |  |  |
| [member/thumbnail](#memberthumbnail) | 2 |  | 1 |  |  |  | 2 |  |  |
| [meta](#meta) | 4 | 3 |  |  |  |  |  |  | 1 |
| [tag](#tag) | 1 |  |  |  |  |  |  |  |  |
| [websockets](#websockets) | 1 |  |  |  |  |  |  |  |  |

## auth/magicLink

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/register`<br>[magicLink.controller.ts:31](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/magicLink/magicLink.controller.ts#L31) | captcha(signUp) | `account`, `action`, `invitation`, `item_membership` | `members_view` | email: generateLoginLinkAndEmailIt, generateRegisterLinkAndEmailIt<br>external: http | `InvitationService.createToMemberships`<br>`MagicLinkService.login`<br>`MagicLinkService.sendRegisterMail`<br>`MemberService.post` |
| `POST /api/login`<br>[magicLink.controller.ts:63](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/magicLink/magicLink.controller.ts#L63) | captcha(signIn) | `action` | `members_view` | email: generateLoginLinkAndEmailIt<br>external: http | `MagicLinkService.login` |
| `GET /api/auth`<br>[magicLink.controller.ts:79](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/magicLink/magicLink.controller.ts#L79) | magic link token | `account` | `members_view` |  | `MemberService.refreshLastAuthenticatedAt`<br>`MemberService.validate` |
| `POST /api/logout`<br>[magicLink.controller.ts:129](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/magicLink/magicLink.controller.ts#L129) | **none** |  |  |  |  |

## auth/password

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/login-password`<br>[password.controller.ts:38](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/password/password.controller.ts#L38) | captcha(signInWithPassword) + password | `account` | `members_view` | external: http | `MemberService.refreshLastAuthenticatedAt` |
| `POST /api/password`<br>[password.controller.ts:69](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/password/password.controller.ts#L69) | session + validated | `member_password` |  |  | `MemberPasswordService.post` |
| `PATCH /api/password`<br>[password.controller.ts:91](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/password/password.controller.ts#L91) | session + validated | `member_password` |  |  | `MemberPasswordService.patch` |
| `POST /api/password/reset`<br>[password.controller.ts:117](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/password/password.controller.ts#L117) | captcha(resetPassword) | `action` | `member_password`, `members_view` | email: mailResetPasswordRequest<br>external: http, redis | `ActionService.postMany`<br>`MemberPasswordService.createResetPasswordRequest`<br>`MemberPasswordService.mailResetPasswordRequest` |
| `PATCH /api/password/reset`<br>[password.controller.ts:158](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/password/password.controller.ts#L158) | password reset token | `action`, `member_password` | `members_view` | external: redis | `ActionService.postMany`<br>`MemberPasswordService.applyReset`<br>`MemberPasswordService.getMemberByPasswordResetUuid` |
| `GET /api/members/current/password/status`<br>[password.controller.ts:194](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/auth/plugins/password/password.controller.ts#L194) | session |  | `member_password` |  | `MemberPasswordService.hasPassword` |

## chat

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:itemId/chat`<br>[chatMessage.controller.ts:57](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/chatMessage.controller.ts#L57) | optional |  | `account`, `chat_message`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ChatMessageService.getForItem` |
| `POST /api/items/:itemId/chat`<br>[chatMessage.controller.ts:65](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/chatMessage.controller.ts#L65) | session + validated or guest | `action`, `chat_mention`, `chat_message` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | ws: itemChat ← ItemChatEvent(publish)<br>email: sendMentionNotificationEmail | `ActionChatService.postPostMessageAction`<br>`ChatMessageService.postOne` |
| `PATCH /api/items/:itemId/chat/:messageId`<br>[chatMessage.controller.ts:99](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/chatMessage.controller.ts#L99) | session + validated or guest | `action`, `chat_message` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | ws: itemChat ← ItemChatEvent(update) | `ActionChatService.postPatchMessageAction`<br>`ChatMessageService.patchOne` |
| `DELETE /api/items/:itemId/chat/:messageId`<br>[chatMessage.controller.ts:130](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/chatMessage.controller.ts#L130) | session + validated or guest | `action`, `chat_message` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | ws: itemChat ← ItemChatEvent(delete) | `ActionChatService.postDeleteMessageAction`<br>`ChatMessageService.deleteOne` |
| `DELETE /api/items/:itemId/chat`<br>[chatMessage.controller.ts:160](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/chatMessage.controller.ts#L160) | session + validated | `action`, `chat_message` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | ws: itemChat ← ItemChatEvent(clear) | `ActionChatService.postClearMessageAction`<br>`ChatMessageService.clear` |

## chat/mentions

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/mentions`<br>[chatMention.controller.ts:22](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/plugins/mentions/chatMention.controller.ts#L22) | session |  | `chat_mention` |  | `MentionService.getForAccount` |
| `PATCH /api/items/mentions/:mentionId`<br>[chatMention.controller.ts:31](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/plugins/mentions/chatMention.controller.ts#L31) | session | `chat_mention` |  |  | `MentionService.patch` |
| `DELETE /api/items/mentions/:mentionId`<br>[chatMention.controller.ts:43](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/plugins/mentions/chatMention.controller.ts#L43) | session | `chat_mention` |  |  | `MentionService.deleteOne` |
| `DELETE /api/items/mentions`<br>[chatMention.controller.ts:55](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/chat/plugins/mentions/chatMention.controller.ts#L55) | session | `chat_mention` |  |  | `MentionService.deleteAll` |

## item

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items`<br>[item.controller.ts:34](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L34) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `ItemActionService.postPostAction`<br>`ItemService.post`<br>`ItemService.rescaleOrderForParent` |
| `GET /api/items/:id`<br>[item.controller.ts:122](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L122) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | storage: getUrl | `ItemService.getPacked` |
| `GET /api/items/accessible`<br>[item.controller.ts:135](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L135) | session + member |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | storage: getUrl | `ItemService.getAccessible`<br>`PackedItemService.createPackedItems` |
| `GET /api/items/:id/children`<br>[item.controller.ts:169](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L169) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | storage: getUrl | `ItemService.getPackedChildren` |
| `GET /api/items/:id/descendants`<br>[item.controller.ts:182](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L182) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | storage: getUrl | `ItemService.getPackedDescendants` |
| `GET /api/items/:id/parents`<br>[item.controller.ts:192](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L192) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemService.getParents` |
| `PATCH /api/items/:id`<br>[item.controller.ts:204](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L204) | session + validated | `action`, `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `ItemActionService.postPatchAction`<br>`ItemService.patch` |
| `PATCH /api/items/:id/reorder`<br>[item.controller.ts:226](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L226) | session + validated | `item` | `account`, `item_membership`, `item_view`, `item_visibility` |  | `ItemService.reorder`<br>`ItemService.rescaleOrderForParent` |
| `DELETE /api/items`<br>[item.controller.ts:255](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L255) | session + validated | `action`, `item` | `item_membership`, `members_view` | ws: memberItems ← ItemOpFeedbackErrorEvent(delete), memberItems ← ItemOpFeedbackEvent(delete)<br>storage: delete, deleteFolder<br>external: etherpad | `ItemActionService.postManyDeleteAction`<br>`ItemService.deleteMany`<br>hook `ItemService:post:delete`<br>hook `ItemService:pre:delete` |
| `POST /api/items/move`<br>[item.controller.ts:297](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L297) | session + validated | `action`, `item`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | ws: memberItems ← ItemOpFeedbackErrorEvent(move), memberItems ← ItemOpFeedbackEvent(move)<br>job: buildIndex<br>search: write | `ItemActionService.postManyMoveAction`<br>`ItemService.moveMany` |
| `POST /api/items/copy`<br>[item.controller.ts:336](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L336) | session + validated | `app_setting`, `item`, `item_geolocation`, `item_membership`, `item_visibility`, `page_update` | `account`, `item_like`, `item_tag`, `item_view`, `members_view`, `published_items` +1 | ws: memberItems ← ItemOpFeedbackErrorEvent(copy), memberItems ← ItemOpFeedbackEvent(copy)<br>job: buildIndex<br>storage: copy, copyFolder<br>search: write<br>external: etherpad | `ItemService.copyMany`<br>hook `AppSettingService:post:copyMany`<br>hook `ItemService:post:copy`<br>hook `ItemService:pre:copy` |
| `POST /api/items/with-thumbnail`<br>[item.controller.ts:84](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/item.controller.ts#L84) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `ItemActionService.postPostAction`<br>`ItemService.post` |

## item/action

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/:id/actions`<br>[itemAction.controller.ts:39](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/action/itemAction.controller.ts#L39) | optional | `action` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` |  | `ActionService.postMany`<br>`AuthorizedItemService.getItemById` |
| `POST /api/items/:id/actions/export`<br>[itemAction.controller.ts:81](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/action/itemAction.controller.ts#L81) | session + validated | `action_request_export` | `account`, `action`, `app_action`, `app_data`, `app_setting`, `chat_message` +5 | ws: memberItems ← ItemOpFeedbackErrorEvent(export), memberItems ← ItemOpFeedbackEvent(export)<br>email: sendExportLinkInMail<br>storage: getUrl, upload | `ActionRequestExportService.request` |
| `GET /api/items/:id/actions/actions-by-day`<br>[itemAction.controller.ts:123](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/action/itemAction.controller.ts#L123) | optional |  | `account`, `action`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemActionService.getActionsByDay` |
| `GET /api/items/:id/actions/actions-by-hour`<br>[itemAction.controller.ts:143](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/action/itemAction.controller.ts#L143) | optional |  | `account`, `action`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemActionService.getActionsByHour` |
| `GET /api/items/:id/actions/actions-by-weekday`<br>[itemAction.controller.ts:163](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/action/itemAction.controller.ts#L163) | optional |  | `account`, `action`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemActionService.getActionsByWeekday` |

## item/app

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/app-items/list`<br>[app.controller.ts:50](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/app.controller.ts#L50) | **none** |  | `apps` |  | `AppService.getAllApps` |
| `GET /api/app-items/most-used`<br>[app.controller.ts:54](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/app.controller.ts#L54) | session |  | `apps`, `item_view` |  | `AppService.getMostUsedApps` |
| `POST /api/app-items/:itemId/api-access-token`<br>[app.controller.ts:64](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/app.controller.ts#L64) | optional |  | `account`, `apps`, `item`, `item_membership`, `item_view`, `item_visibility` +1 |  | `AppService.getApiAccessToken` |
| `GET /api/app-items/:itemId/context`<br>[app.controller.ts:104](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/app.controller.ts#L104) | app JWT (guest ok) |  | `account`, `item`, `item_membership`, `item_view` |  | `AppService.getContext` |
| `POST /api/items/apps`<br>[appItem.controller.ts:18](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appItem.controller.ts#L18) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `AppItemService.postWithOptions`<br>`ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent` |
| `PATCH /api/items/apps/:id`<br>[appItem.controller.ts:52](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appItem.controller.ts#L52) | session + validated | `action`, `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `AppItemService.patch`<br>`ItemActionService.postPatchAction` |

## item/app/appAction

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/app-items/:itemId/app-action`<br>[appAction.controller.ts:37](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appAction/appAction.controller.ts#L37) | app JWT | `app_action` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appActions ← AppActionEvent(post) | `AppActionService.post` |
| `GET /api/app-items/:itemId/app-action`<br>[appAction.controller.ts:54](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appAction/appAction.controller.ts#L54) | app JWT |  | `account`, `app_action`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AppActionService.getForItem` |

## item/app/appData

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/app-items/:itemId/app-data`<br>[appData.controller.ts:59](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appData/appData.controller.ts#L59) | app JWT | `app_data` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appData ← AppDataEvent(post) | `AppDataService.post` |
| `PATCH /api/app-items/:itemId/app-data/:id`<br>[appData.controller.ts:80](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appData/appData.controller.ts#L80) | app JWT | `app_data` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appData ← AppDataEvent(patch) | `AppDataService.patch` |
| `DELETE /api/app-items/:itemId/app-data/:id`<br>[appData.controller.ts:97](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appData/appData.controller.ts#L97) | app JWT | `app_data` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appData ← AppDataEvent(delete)<br>storage: delete | `AppDataService.deleteOne` |
| `GET /api/app-items/:itemId/app-data`<br>[appData.controller.ts:114](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appData/appData.controller.ts#L114) | app JWT |  | `account`, `app_data`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AppDataService.getForItem` |
| `POST /api/app-items/app-data/upload`<br>[appData.controller.ts:124](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appData/appData.controller.ts#L124) | app JWT (guest ok) | `app_data` |  | storage: upload | `AppDataService.upload` |
| `GET /api/app-items/app-data/:id/download`<br>[appData.controller.ts:159](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appData/appData.controller.ts#L159) | app JWT (guest ok) |  | `account`, `app_data`, `item`, `item_membership`, `item_visibility` | storage: getUrl | `AppDataService.download` |

## item/app/appSetting

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/app-items/:itemId/app-settings`<br>[appSetting.controller.ts:51](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appSetting/appSetting.controller.ts#L51) | app JWT + validated | `app_setting` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appSettings ← AppSettingEvent(post) | `AppSettingService.post` |
| `PATCH /api/app-items/:itemId/app-settings/:id`<br>[appSetting.controller.ts:71](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appSetting/appSetting.controller.ts#L71) | app JWT + validated | `app_setting` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appSettings ← AppSettingEvent(patch) | `AppSettingService.patch` |
| `DELETE /api/app-items/:itemId/app-settings/:id`<br>[appSetting.controller.ts:91](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appSetting/appSetting.controller.ts#L91) | app JWT + validated | `app_setting` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | ws: appSettings ← AppSettingEvent(delete)<br>storage: delete | `AppSettingService.deleteOne`<br>hook `AppSettingService:post:delete` |
| `GET /api/app-items/:itemId/app-settings`<br>[appSetting.controller.ts:111](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appSetting/appSetting.controller.ts#L111) | app JWT (guest ok) |  | `account`, `app_setting`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AppSettingService.getForItem` |

## item/app/appSetting/file

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/app-items/app-settings/upload`<br>[appSetting.file.controller.ts:80](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appSetting/plugins/file/appSetting.file.controller.ts#L80) | app JWT (guest ok) | `app_setting` |  | storage: upload | `AppSettingFileService.upload` |
| `GET /api/app-items/app-settings/:id/download`<br>[appSetting.file.controller.ts:115](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/appSetting/plugins/file/appSetting.file.controller.ts#L115) | app JWT |  | `account`, `app_setting`, `item`, `item_membership`, `item_view`, `item_visibility` | storage: getUrl | `AppSettingFileService.download` |

## item/app/chatBot

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/app-items/:itemId/chat-bot`<br>[chatBot.controller.ts:28](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/app/chatBot/chatBot.controller.ts#L28) | app JWT |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | external: openai | `AuthorizedItemService.getItemById`<br>`ChatBotService.post` |

## item/capsule

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/capsules`<br>[capsule.controller.ts:19](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/capsule/capsule.controller.ts#L19) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `CapsuleItemService.create`<br>`ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent` |
| `POST /api/items/capsules/:id/convert`<br>[capsule.controller.ts:53](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/capsule/capsule.controller.ts#L53) | session + validated | `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `CapsuleItemService.convertToFolder` |

## item/document

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/documents`<br>[document.controller.ts:17](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/document/document.controller.ts#L17) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `DocumentItemService.postWithOptions`<br>`ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent` |
| `PATCH /api/items/documents/:id`<br>[document.controller.ts:51](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/document/document.controller.ts#L51) | session + validated | `action`, `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `DocumentItemService.patchWithOptions`<br>`ItemActionService.postPatchAction` |

## item/embeddedLink

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/embedded-links/metadata`<br>[link.controller.ts:19](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/embeddedLink/link.controller.ts#L19) | session |  |  | external: http | `EmbeddedLinkItemService.checkEmbeddingAllowed`<br>`EmbeddedLinkItemService.getLinkMetadata` |
| `POST /api/items/embedded-links`<br>[link.controller.ts:34](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/embeddedLink/link.controller.ts#L34) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write<br>external: http | `EmbeddedLinkItemService.postWithOptions`<br>`ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent` |
| `PATCH /api/items/embedded-links/:id`<br>[link.controller.ts:68](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/embeddedLink/link.controller.ts#L68) | session + validated | `action`, `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write<br>external: http | `EmbeddedLinkItemService.patchWithOptions`<br>`ItemActionService.postPatchAction` |

## item/enroll

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/:itemId/enroll`<br>[enroll.controller.ts:18](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/enroll/enroll.controller.ts#L18) | session + validated | `item_membership` | `account`, `item`, `item_login_schema`, `item_view`, `item_visibility` |  | `EnrollService.enroll` |

## item/etherpad

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/etherpad/create`<br>[etherpad.controller.ts:24](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/etherpad/etherpad.controller.ts#L24) | session + validated | `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write<br>external: etherpad | `EtherpadItemService.createEtherpadItem` |
| `PATCH /api/items/etherpad/:id`<br>[etherpad.controller.ts:50](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/etherpad/etherpad.controller.ts#L50) | session + validated | `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `EtherpadItemService.patchWithOptions` |
| `GET /api/items/etherpad/view/:itemId`<br>[etherpad.controller.ts:77](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/etherpad/etherpad.controller.ts#L77) | session |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | external: etherpad | `EtherpadItemService.getEtherpadFromItem` |

## item/file

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/upload`<br>[itemFile.controller.ts:96](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/file/itemFile.controller.ts#L96) | session + validated | `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: delete, deleteFolder, getFileSize, upload, uploadMany<br>search: write | `AuthorizedItemService.assertAccessForItemId`<br>`FileItemService.uploadFileAndCreateItem`<br>`H5PService.uploadFileAndCreateItem`<br>`ItemService.rescaleOrderForParent` |
| `GET /api/items/:id/download`<br>[itemFile.controller.ts:181](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/file/itemFile.controller.ts#L181) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | storage: getUrl | `FileItemService.getUrl` |
| `PATCH /api/items/files/:id`<br>[itemFile.controller.ts:201](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/file/itemFile.controller.ts#L201) | session | `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `FileItemService.update` |

## item/folder

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/folders`<br>[folder.controller.ts:25](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/folder/folder.controller.ts#L25) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `FolderItemService.postWithOptions`<br>`ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent` |
| `PATCH /api/items/folders/:id`<br>[folder.controller.ts:106](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/folder/folder.controller.ts#L106) | session + validated | `action`, `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `FolderItemService.patch`<br>`ItemActionService.postPatchAction` |
| `POST /api/items/folders/:id/convert`<br>[folder.controller.ts:128](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/folder/folder.controller.ts#L128) | session + validated | `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `FolderItemService.convertToCapsule` |
| `POST /api/items/folders-with-thumbnail`<br>[folder.controller.ts:70](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/folder/folder.controller.ts#L70) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `FolderItemService.postWithOptions`<br>`ItemActionService.postPostAction` |

## item/geolocation

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:id/geolocation`<br>[itemGeolocation.controller.ts:28](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/geolocation/itemGeolocation.controller.ts#L28) | optional |  | `account`, `item`, `item_geolocation`, `item_membership`, `item_view`, `item_visibility` +1 | storage: getUrl | `ItemGeolocationService.getByItem`<br>`ItemService.getPacked` |
| `GET /api/items/geolocation`<br>[itemGeolocation.controller.ts:47](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/geolocation/itemGeolocation.controller.ts#L47) | optional |  | `account`, `item`, `item_geolocation`, `item_membership`, `item_tag`, `item_view` +2 | storage: getUrl | `ItemGeolocationService.getIn` |
| `PUT /api/items/:id/geolocation`<br>[itemGeolocation.controller.ts:58](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/geolocation/itemGeolocation.controller.ts#L58) | session + validated | `item_geolocation` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemGeolocationService.put` |
| `DELETE /api/items/:id/geolocation`<br>[itemGeolocation.controller.ts:74](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/geolocation/itemGeolocation.controller.ts#L74) | session + validated | `item_geolocation` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemGeolocationService.delete` |
| `GET /api/items/geolocation/reverse`<br>[itemGeolocation.controller.ts:90](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/geolocation/itemGeolocation.controller.ts#L90) | session |  |  | external: http | `ItemGeolocationService.getAddressFromCoordinates` |
| `GET /api/items/geolocation/search`<br>[itemGeolocation.controller.ts:101](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/geolocation/itemGeolocation.controller.ts#L101) | session |  |  | external: http | `ItemGeolocationService.getSuggestionsForQuery` |

## item/html/h5p

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/h5p-import`<br>[h5p.controller.ts:90](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/html/h5p/h5p.controller.ts#L90) | session + validated | `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: deleteFolder, upload, uploadMany<br>search: write | `AuthorizedItemService.assertAccessForItemId`<br>`H5PService.uploadFileAndCreateItem` |

## item/importExport

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/zip-import`<br>[importExport.controller.ts:54](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/importExport/importExport.controller.ts#L54) | session + validated | `app_setting`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: delete, deleteFolder, getFileSize, upload, uploadMany<br>search: write | `ImportService.import` |
| `GET /api/items/:itemId/download-file`<br>[importExport.controller.ts:102](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/importExport/importExport.controller.ts#L102) | optional | `action` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | storage: getUrl<br>external: etherpad, http | `ActionService.postMany`<br>`AuthorizedItemService.getItemById`<br>`ItemExportService.fetchItemData` |
| `POST /api/items/:itemId/export`<br>[importExport.controller.ts:146](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/importExport/importExport.controller.ts#L146) | session + validated |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | job: exportFolderZip | `AuthorizedItemService.getItemById` |
| `POST /api/items/:itemId/graasp-export`<br>[importExport.controller.ts:185](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/importExport/importExport.controller.ts#L185) | optional |  | `account`, `app_setting`, `item`, `item_membership`, `item_view`, `item_visibility` +1 | storage: getFile, getUrl<br>external: etherpad, http | `AuthorizedItemService.getItemById`<br>`GraaspExportService.exportGraasp` |

## item/invitation

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/invitations/:id`<br>[invitation.controller.ts:37](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L37) | optional |  | `invitation`, `item_view` |  | `InvitationService.get` |
| `POST /api/items/:id/invite`<br>[invitation.controller.ts:51](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L51) | session + validated | `invitation`, `item_membership`, `membership_request` | `account`, `item`, `item_view`, `item_visibility`, `members_view` | ws: itemMemberships ← ItemMembershipEvent(create)<br>email: sendInvitationEmail, _notifyMember | `InvitationService.shareItem`<br>hook `ItemMembershipService:post:create` |
| `GET /api/items/:id/invitations`<br>[invitation.controller.ts:155](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L155) | session + member |  | `account`, `invitation`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `InvitationService.getForItem` |
| `PATCH /api/items/:id/invitations/:invitationId`<br>[invitation.controller.ts:169](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L169) | session + validated | `invitation` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `InvitationService.patch` |
| `DELETE /api/items/:id/invitations/:invitationId`<br>[invitation.controller.ts:186](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L186) | session + validated | `invitation` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `InvitationService.delete` |
| `POST /api/items/:id/invitations/:invitationId/send`<br>[invitation.controller.ts:203](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L203) | session + validated |  | `account`, `invitation`, `item`, `item_membership`, `item_view`, `item_visibility` | email: sendInvitationEmail | `InvitationService.resend` |
| `POST /api/items/:id/invitations/upload-csv-template`<br>[invitation.controller.ts:78](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L78) | session + validated | `app_setting`, `invitation`, `item`, `item_geolocation`, `item_membership`, `item_visibility`, `membership_request`, `page_update` | `account`, `item_like`, `item_tag`, `item_view`, `members_view`, `published_items` +1 | ws: itemMemberships ← ItemMembershipEvent(create)<br>email: sendInvitationEmail, _notifyMember<br>job: buildIndex<br>storage: copy, copyFolder<br>search: write<br>external: etherpad | `InvitationService.createStructureForCSVAndTemplate`<br>hook `AppSettingService:post:copyMany`<br>hook `ItemMembershipService:post:create`<br>hook `ItemService:post:copy`<br>hook `ItemService:pre:copy` |
| `POST /api/items/:id/invitations/upload-csv`<br>[invitation.controller.ts:119](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/invitation/invitation.controller.ts#L119) | session + validated | `invitation`, `item_membership`, `membership_request` | `account`, `item`, `item_view`, `item_visibility`, `members_view` | ws: itemMemberships ← ItemMembershipEvent(create)<br>email: sendInvitationEmail, _notifyMember | `InvitationService.importUsersWithCSV`<br>hook `ItemMembershipService:post:create` |

## item/itemBookmark

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/bookmarks`<br>[itemBookmark.controller.ts:18](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemBookmark/itemBookmark.controller.ts#L18) | session + member |  | `account`, `item`, `item_favorite`, `item_membership`, `item_view`, `item_visibility` +1 | storage: getUrl | `BookmarkService.getOwn` |
| `POST /api/items/bookmarks/:itemId`<br>[itemBookmark.controller.ts:32](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemBookmark/itemBookmark.controller.ts#L32) | session + validated | `item_favorite` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `BookmarkService.post` |
| `DELETE /api/items/bookmarks/:itemId`<br>[itemBookmark.controller.ts:45](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemBookmark/itemBookmark.controller.ts#L45) | session + validated | `item_favorite` |  |  | `BookmarkService.delete` |

## item/itemFlag

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/flags`<br>[itemFlag.controller.ts:18](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemFlag/itemFlag.controller.ts#L18) | **none** |  |  |  | `ItemFlagService.getAllFlagTypes` |
| `POST /api/items/:itemId/flags`<br>[itemFlag.controller.ts:23](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemFlag/itemFlag.controller.ts#L23) | session + validated or guest | `item_flag` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemFlagService.post` |

## item/itemLike

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/liked`<br>[itemLike.controller.ts:23](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemLike/itemLike.controller.ts#L23) | session + member |  | `account`, `item`, `item_like`, `item_membership`, `item_visibility` |  | `ItemLikeService.getForMember` |
| `GET /api/items/:itemId/likes`<br>[itemLike.controller.ts:38](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemLike/itemLike.controller.ts#L38) | optional |  | `account`, `item`, `item_like`, `item_membership`, `item_view`, `item_visibility` |  | `ItemLikeService.getForItem` |
| `POST /api/items/:itemId/like`<br>[itemLike.controller.ts:47](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemLike/itemLike.controller.ts#L47) | session + validated | `action`, `item_like` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` +1 | search: write | `ActionService.postMany`<br>`AuthorizedItemService.getItemById`<br>`ItemLikeService.post` |
| `DELETE /api/items/:itemId/like`<br>[itemLike.controller.ts:75](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemLike/itemLike.controller.ts#L75) | session + validated | `action`, `item_like` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` +1 | search: write | `ActionService.postMany`<br>`AuthorizedItemService.getItemById`<br>`ItemLikeService.removeOne` |

## item/itemVisibility

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/:itemId/visibilities/:type`<br>[itemVisibility.controller.ts:27](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemVisibility/itemVisibility.controller.ts#L27) | session + validated | `item_visibility` | `account`, `item`, `item_membership`, `item_view` |  | `ItemVisibilityService.post` |
| `DELETE /api/items/:itemId/visibilities/:type`<br>[itemVisibility.controller.ts:41](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/itemVisibility/itemVisibility.controller.ts#L41) | session + validated | `item_visibility` | `account`, `item`, `item_membership`, `item_view` |  | `ItemVisibilityService.deleteOne` |

## item/page

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/pages`<br>[page.controller.ts:31](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/page/page.controller.ts#L31) | session + validated | `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `PageItemService.create` |
| `GET /api/items/pages/:id/ws/read` (websocket)<br>[page.controller.ts:60](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/page/page.controller.ts#L60) | optional + item read check | `page_update` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AuthorizedItemService.getItemById` |
| `GET /api/items/pages/:id/ws` (websocket)<br>[page.controller.ts:86](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/page/page.controller.ts#L86) | session + validated + item write check | `page_update` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AuthorizedItemService.getItemById` |

## item/publication/publicationState

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/publication/:itemId/status`<br>[publication.controller.ts:14](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/publicationState/publication.controller.ts#L14) | session |  | `account`, `item`, `item_membership`, `item_validation_group`, `item_view`, `item_visibility` +2 | external: redis | `PublicationService.computeStateForItem` |

## item/publication/published

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/collections/members/:memberId`<br>[itemPublished.controller.ts:33](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/itemPublished.controller.ts#L33) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `published_items` | storage: getUrl | `ItemPublishedService.getItemsForMember` |
| `GET /api/items/collections/:itemId/informations`<br>[itemPublished.controller.ts:44](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/itemPublished.controller.ts#L44) | optional |  | `account`, `action`, `item`, `item_membership`, `item_view`, `item_visibility` +2 |  | `ItemPublishedService.get` |
| `POST /api/items/collections/:itemId/publish`<br>[itemPublished.controller.ts:56](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/itemPublished.controller.ts#L56) | session + validated | `item_visibility`, `published_items` | `account`, `item`, `item_like`, `item_membership`, `item_tag`, `item_validation_group` +3 | email: _notifyContributors<br>job: buildIndex<br>search: write<br>external: redis | `AuthorizedItemService.getItemById`<br>`ItemPublishedService.post`<br>`PublicationService.computeStateForItem` |
| `DELETE /api/items/collections/:itemId/unpublish`<br>[itemPublished.controller.ts:80](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/itemPublished.controller.ts#L80) | session + validated | `published_items` | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `members_view` | job: buildIndex<br>search: write | `ItemPublishedService.delete`<br>hook `ItemPublishedService:post:delete` |

## item/publication/published/search

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/collections/search`<br>[search.controller.ts:31](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/plugins/search/search.controller.ts#L31) | optional | `action` | `members_view` | storage: getUrl<br>search: query | `ActionService.postMany`<br>`SearchService.search` |
| `POST /api/items/collections/facets`<br>[search.controller.ts:48](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/plugins/search/search.controller.ts#L48) | optional |  |  | search: query | `SearchService.getFacets` |
| `GET /api/items/collections/featured`<br>[search.controller.ts:58](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/plugins/search/search.controller.ts#L58) | optional |  |  | storage: getUrl<br>search: query | `SearchService.getFeatured` |
| `GET /api/items/collections/liked`<br>[search.controller.ts:67](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/plugins/search/search.controller.ts#L67) | optional |  |  | storage: getUrl<br>search: query | `SearchService.getMostLiked` |
| `GET /api/items/collections/recent`<br>[search.controller.ts:76](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/plugins/search/search.controller.ts#L76) | optional |  |  | storage: getUrl<br>search: query | `SearchService.getMostRecent` |
| `GET /api/items/collections/search/rebuild`<br>[search.controller.ts:85](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/published/plugins/search/search.controller.ts#L85) | header secret `meilisearch-rebuild` |  |  | job: buildIndex |  |

## item/publication/validation

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:itemId/validations/latest`<br>[itemValidation.controller.ts:34](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/validation/itemValidation.controller.ts#L34) | session + member |  | `account`, `item`, `item_membership`, `item_validation_group`, `item_view`, `item_visibility` |  | `AuthorizedItemService.getItemById`<br>`ItemValidationService.getLastItemValidationGroupForItem` |
| `POST /api/items/:itemId/validate`<br>[itemValidation.controller.ts:53](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/publication/validation/itemValidation.controller.ts#L53) | session + validated | `item_validation`, `item_validation_group`, `item_validation_review`, `item_visibility`, `published_items` | `account`, `item`, `item_like`, `item_membership`, `item_tag`, `item_view` +2 | ws: memberItems ← ItemOpFeedbackErrorEvent(validate), memberItems ← ItemOpFeedbackEvent(validate)<br>email: _notifyContributors<br>job: buildIndex<br>storage: getUrl<br>search: write<br>external: http, redis | `FolderItemService.getFolder`<br>`ItemPublishedService.publishIfNotExist`<br>`ItemValidationService.post` |

## item/recycled

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/recycled`<br>[recycled.controller.ts:33](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/recycled/recycled.controller.ts#L33) | session + member |  | `item`, `item_membership`, `members_view`, `recycled_item_data` |  | `RecycledBinService.getOwn` |
| `POST /api/items/recycle`<br>[recycled.controller.ts:52](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/recycled/recycled.controller.ts#L52) | session + validated | `item`, `recycled_item_data` | `account`, `item_membership`, `item_view`, `item_visibility`, `members_view` | ws: memberItems ← ItemOpFeedbackErrorEvent(recycle), memberItems ← ItemOpFeedbackEvent(recycle) | `RecycledBinService.recycleMany` |
| `POST /api/items/restore`<br>[recycled.controller.ts:92](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/recycled/recycled.controller.ts#L92) | session + validated | `item`, `recycled_item_data` | `account`, `item_membership`, `item_visibility` | ws: memberItems ← ItemOpFeedbackErrorEvent(restore), memberItems ← ItemOpFeedbackEvent(restore) | `RecycledBinService.restoreMany` |

## item/shortLink

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/short-links/:alias`<br>[shortlink.controller.ts:27](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortLink/shortlink.controller.ts#L27) | **none** |  | `short_link` |  | `ShortLinkService.getRedirection` |
| `GET /api/items/short-links/available/:alias`<br>[shortlink.controller.ts:32](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortLink/shortlink.controller.ts#L32) | **none** |  | `short_link` |  | `ShortLinkService.getOne` |
| `GET /api/items/short-links/list/:itemId`<br>[shortlink.controller.ts:43](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortLink/shortlink.controller.ts#L43) | session |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `short_link` |  | `ShortLinkService.getAllForItem` |
| `POST /api/items/short-links`<br>[shortlink.controller.ts:52](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortLink/shortlink.controller.ts#L52) | session + validated | `short_link` | `account`, `action`, `item`, `item_membership`, `item_view`, `item_visibility` +2 |  | `ShortLinkService.post` |
| `DELETE /api/items/short-links/:alias`<br>[shortlink.controller.ts:68](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortLink/shortlink.controller.ts#L68) | session + validated | `short_link` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ShortLinkService.delete` |
| `PATCH /api/items/short-links/:alias`<br>[shortlink.controller.ts:84](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortLink/shortlink.controller.ts#L84) | session + validated | `short_link` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ShortLinkService.update` |

## item/shortcut

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/shortcuts`<br>[shortcut.controller.ts:19](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortcut/shortcut.controller.ts#L19) | session + validated | `action`, `item`, `item_geolocation`, `item_membership` | `account`, `item_like`, `item_tag`, `item_view`, `item_visibility`, `members_view` +2 | job: buildIndex<br>storage: uploadMany<br>search: write | `ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent`<br>`ShortcutItemService.postWithOptions` |
| `PATCH /api/items/shortcuts/:id`<br>[shortcut.controller.ts:55](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/shortcut/shortcut.controller.ts#L55) | session + validated | `action`, `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `ItemActionService.postPostAction`<br>`ItemService.rescaleOrderForParent`<br>`ShortcutItemService.patch` |

## item/tag

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:itemId/tags`<br>[itemTag.controller.ts:17](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/tag/itemTag.controller.ts#L17) | optional |  | `account`, `item`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +1 |  | `ItemTagService.getByItemId` |
| `POST /api/items/:itemId/tags`<br>[itemTag.controller.ts:25](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/tag/itemTag.controller.ts#L25) | session + validated | `item_tag`, `tag` | `account`, `item`, `item_like`, `item_membership`, `item_view`, `item_visibility` +2 | job: buildIndex<br>search: write | `ItemTagService.create` |
| `DELETE /api/items/:itemId/tags/:tagId`<br>[itemTag.controller.ts:41](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/tag/itemTag.controller.ts#L41) | session + validated | `item_tag` | `account`, `item`, `item_like`, `item_membership`, `item_view`, `item_visibility` +3 | job: buildIndex<br>search: write | `ItemTagService.delete` |

## item/thumbnail

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/items/:id/thumbnails`<br>[itemThumbnail.controller.ts:41](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/thumbnail/itemThumbnail.controller.ts#L41) | session + validated | `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>storage: uploadMany<br>search: write | `ItemThumbnailService.upload` |
| `GET /api/items/:id/thumbnails/:size`<br>[itemThumbnail.controller.ts:82](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/thumbnail/itemThumbnail.controller.ts#L82) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` | storage: getUrl | `ItemThumbnailService.getUrl` |
| `DELETE /api/items/:id/thumbnails`<br>[itemThumbnail.controller.ts:102](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/item/plugins/thumbnail/itemThumbnail.controller.ts#L102) | session + validated | `item` | `account`, `item_like`, `item_membership`, `item_tag`, `item_view`, `item_visibility` +3 | job: buildIndex<br>storage: delete<br>search: write | `ItemThumbnailService.deleteAllThumbnailSizes` |

## itemLogin

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:id/login-schema-type`<br>[itemLogin.controller.ts:39](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemLogin/itemLogin.controller.ts#L39) | optional |  | `account`, `item_login_schema`, `item_membership`, `item_view`, `item_visibility` |  | `ItemLoginService.getByItemPath`<br>`ItemLoginService.isItemVisible` |
| `GET /api/items/:id/login-schema`<br>[itemLogin.controller.ts:64](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemLogin/itemLogin.controller.ts#L64) | session |  | `account`, `item`, `item_login_schema`, `item_membership`, `item_view`, `item_visibility` |  | `AuthorizedItemService.getItemById`<br>`ItemLoginService.getByItemPath` |
| `POST /api/items/:id/login`<br>[itemLogin.controller.ts:86](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemLogin/itemLogin.controller.ts#L86) | optional | `account`, `guest_password`, `item_membership` | `guests_view`, `item`, `item_login_schema`, `item_view` |  | `ItemLoginService.logInOrRegister` |
| `PUT /api/items/:id/login-schema`<br>[itemLogin.controller.ts:107](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemLogin/itemLogin.controller.ts#L107) | session + validated | `item_login_schema` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AuthorizedItemService.getItemById`<br>`ItemLoginService.updateOrCreate` |
| `DELETE /api/items/:id/login-schema`<br>[itemLogin.controller.ts:131](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemLogin/itemLogin.controller.ts#L131) | session + validated | `item_login_schema` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AuthorizedItemService.getItemById`<br>`ItemLoginService.delete` |

## itemMembership

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:itemId/memberships`<br>[membership.controller.ts:30](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/membership.controller.ts#L30) | optional |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `ItemMembershipService.getForItem` |
| `POST /api/items/:itemId/memberships`<br>[membership.controller.ts:39](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/membership.controller.ts#L39) | session + validated | `item_membership`, `membership_request` | `account`, `item`, `item_view`, `item_visibility`, `members_view` | ws: itemMemberships ← ItemMembershipEvent(create)<br>email: _notifyMember | `ItemMembershipService.create`<br>hook `ItemMembershipService:post:create` |
| `PATCH /api/items/:itemId/memberships/:id`<br>[membership.controller.ts:59](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/membership.controller.ts#L59) | session + validated | `item_membership` | `account`, `item`, `item_visibility` | ws: itemMemberships ← ItemMembershipEvent(update) | `ItemMembershipService.patch`<br>hook `ItemMembershipService:post:update` |
| `DELETE /api/items/:itemId/memberships/:id`<br>[membership.controller.ts:75](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/membership.controller.ts#L75) | session | `item_membership` | `account`, `item`, `item_visibility` | ws: itemMemberships ← ItemMembershipEvent(delete) | `ItemMembershipService.deleteOne`<br>hook `ItemMembershipService:post:delete` |

## itemMembership/MembershipRequest

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/items/:itemId/memberships/requests`<br>[membershipRequest.controller.ts:34](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/plugins/MembershipRequest/membershipRequest.controller.ts#L34) | session + validated |  | `account`, `item`, `item_membership`, `item_view`, `item_visibility`, `membership_request` |  | `AuthorizedItemService.assertAccessForItemId`<br>`MembershipRequestService.getAllByItem` |
| `GET /api/items/:itemId/memberships/requests/own`<br>[membershipRequest.controller.ts:58](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/plugins/MembershipRequest/membershipRequest.controller.ts#L58) | session + validated |  | `item_membership`, `item_view`, `membership_request` |  | `ItemMembershipService.hasMembershipOnItem`<br>`MembershipRequestService.get` |
| `POST /api/items/:itemId/memberships/requests`<br>[membershipRequest.controller.ts:95](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/plugins/MembershipRequest/membershipRequest.controller.ts#L95) | session + validated | `membership_request` | `account`, `item`, `item_login_schema`, `item_membership`, `item_view`, `item_visibility` +1 | email: notifyAdmins | `AuthorizedItemService.hasPermission`<br>`ItemLoginService.getByItemPath`<br>`MembershipRequestService.get`<br>`MembershipRequestService.notifyAdmins`<br>`MembershipRequestService.post` |
| `DELETE /api/items/:itemId/memberships/requests/:memberId`<br>[membershipRequest.controller.ts:136](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/itemMembership/plugins/MembershipRequest/membershipRequest.controller.ts#L136) | session + validated | `membership_request` | `account`, `item`, `item_membership`, `item_view`, `item_visibility` |  | `AuthorizedItemService.assertAccessForItemId`<br>`MembershipRequestService.deleteOne` |

## maintenance

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/maintenance/next`<br>[maintenance.controller.ts:18](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/maintenance/maintenance.controller.ts#L18) | **none** |  | `maintenance` |  | `MaintenanceService.getNext` |

## member

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/members/current`<br>[member.controller.ts:48](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L48) | session |  | `account`, `item_login_schema` |  |  |
| `GET /api/members/current/storage`<br>[member.controller.ts:91](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L91) | session + member |  | `item_view` |  | `StorageService.getStorageLimits` |
| `GET /api/members/current/storage/files`<br>[member.controller.ts:104](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L104) | session + member |  | `item_view` |  | `StorageService.getStorageFilesMetadata` |
| `GET /api/members/:id`<br>[member.controller.ts:132](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L132) | optional |  | `members_view` |  | `MemberService.get` |
| `PATCH /api/members/current`<br>[member.controller.ts:142](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L142) | session | `account` | `members_view` |  | `MemberService.patch` |
| `DELETE /api/members/current`<br>[member.controller.ts:154](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L154) | session | `account` |  |  | `MemberService.deleteCurrent` |
| `POST /api/members/current/email/change`<br>[member.controller.ts:170](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L170) | session + member |  | `members_view` | email: sendEmailChangeRequest | `MemberService.createEmailChangeRequest`<br>`MemberService.get`<br>`MemberService.getByEmail`<br>`MemberService.sendEmailChangeRequest` |
| `PATCH /api/members/current/email/change`<br>[member.controller.ts:197](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L197) | email change token + member | `account` | `members_view` | email: mailConfirmEmailChangeRequest | `MemberService.get`<br>`MemberService.getByEmail`<br>`MemberService.mailConfirmEmailChangeRequest`<br>`MemberService.patch` |
| `POST /api/members/current/marketing/subscribe`<br>[member.controller.ts:232](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L232) | session + member | `account`, `action` | `members_view` |  | `ActionService.postMany`<br>`MemberService.updateMarketingEmailsSubscription` |
| `POST /api/members/current/marketing/unsubscribe`<br>[member.controller.ts:256](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L256) | session + member | `account`, `action` | `members_view` |  | `ActionService.postMany`<br>`MemberService.updateMarketingEmailsSubscription` |
| `GET /api/members/current/settings`<br>[member.controller.ts:283](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/member.controller.ts#L283) | session + member |  | `members_view` |  | `MemberService.getSettings` |

## member/action

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/members/actions`<br>[memberAction.controller.ts:13](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/action/memberAction.controller.ts#L13) | session |  | `action`, `item`, `item_membership`, `item_visibility` |  | `ActionMemberService.getFilteredActions` |
| `DELETE /api/members/members/:id/delete`<br>[memberAction.controller.ts:24](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/action/memberAction.controller.ts#L24) | session | `action` |  |  | `ActionMemberService.deleteAllForMember` |

## member/export-data

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/members/export-data`<br>[memberExportData.controller.ts:23](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/export-data/memberExportData.controller.ts#L23) | session + member |  | `action`, `app_action`, `app_data`, `app_setting`, `chat_mention`, `chat_message` +5 | email: sendExportLinkInMail<br>storage: getUrl, upload | `ExportMemberDataService.createArchiveAndSendByEmail` |

## member/profile

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/members/profile/own`<br>[memberProfile.controller.ts:22](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/profile/memberProfile.controller.ts#L22) | session |  | `member_profile` |  | `MemberProfileService.getOwn` |
| `GET /api/members/profile/:memberId`<br>[memberProfile.controller.ts:32](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/profile/memberProfile.controller.ts#L32) | optional |  | `member_profile` |  | `MemberProfileService.get` |
| `POST /api/members/profile`<br>[memberProfile.controller.ts:44](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/profile/memberProfile.controller.ts#L44) | session + validated | `member_profile` |  |  | `MemberProfileService.post` |
| `PATCH /api/members/profile`<br>[memberProfile.controller.ts:62](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/profile/memberProfile.controller.ts#L62) | session + validated | `member_profile` |  |  | `MemberProfileService.patch` |

## member/thumbnail

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `POST /api/members/avatar`<br>[memberThumbnail.controller.ts:40](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/thumbnail/memberThumbnail.controller.ts#L40) | session + validated | `account` | `members_view` | storage: uploadMany | `MemberThumbnailService.upload` |
| `GET /api/members/:id/avatar/:size`<br>[memberThumbnail.controller.ts:78](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/member/plugins/thumbnail/memberThumbnail.controller.ts#L78) | optional |  | `account` | storage: getUrl | `MemberThumbnailService.getUrl` |

## meta

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /health`<br>[meta.ts:89](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/plugins/meta.ts#L89) | **none** |  |  |  |  |
| `GET /api/status`<br>[meta.ts:95](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/plugins/meta.ts#L95) | **none** |  |  |  |  |
| `GET /api/version`<br>[meta.ts:115](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/plugins/meta.ts#L115) | **none** |  |  |  |  |
| `GET /api/bust-cache`<br>[meta.ts:119](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/plugins/meta.ts#L119) | admin shared secret |  |  | external: redis |  |

## tag

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/tags`<br>[tag.controller.ts:20](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/tag/tag.controller.ts#L20) | optional |  | `item_tag`, `tag` |  | `TagService.getCountBy` |

## websockets

| Route | Auth | Writes | Reads | Side effects | Calls / hooks |
|---|---|---|---|---|---|
| `GET /api/ws` (websocket)<br>[websocket.controller.ts:56](https://github.com/graasp/graasp/blob/98fa6685304bf03476e569c53605b6f8d09a6793/src/services/websockets/websocket.controller.ts#L56) | optional |  |  |  |  |
