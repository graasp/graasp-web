# Core side-effect index

Generated from core at [`98fa66853`](https://github.com/graasp/graasp/tree/98fa6685304bf03476e569c53605b6f8d09a6793) by `scripts/regenerate.sh`. Do not edit by hand.

Reverse view of [ROUTES.md](ROUTES.md): for each table or side effect, the routes that reach it.

## Tables

Written by: the routes that insert, update or delete rows. Read by: route count only, since the permission tables are read almost everywhere.

| Table | Written by | Read by |
|---|---|---:|
| `account` | `POST /api/register`<br>`GET /api/auth`<br>`POST /api/login-password`<br>`PATCH /api/members/current`<br>`DELETE /api/members/current`<br>`PATCH /api/members/current/email/change`<br>`POST /api/members/current/marketing/subscribe`<br>`POST /api/members/current/marketing/unsubscribe`<br>`POST /api/members/avatar`<br>`POST /api/items/:id/login` | 117 |
| `action` | `POST /api/register`<br>`POST /api/login`<br>`POST /api/password/reset`<br>`PATCH /api/password/reset`<br>`DELETE /api/members/members/:id/delete`<br>`POST /api/members/current/marketing/subscribe`<br>`POST /api/members/current/marketing/unsubscribe`<br>`POST /api/items/collections/search`<br>`POST /api/items/shortcuts`<br>`PATCH /api/items/shortcuts/:id`<br>`POST /api/items/folders`<br>`PATCH /api/items/folders/:id`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/apps`<br>`PATCH /api/items/apps/:id`<br>`GET /api/items/:itemId/download-file`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id`<br>`POST /api/items/documents`<br>`PATCH /api/items/documents/:id`<br>`POST /api/items/:itemId/like`<br>`DELETE /api/items/:itemId/like`<br>`POST /api/items/:itemId/chat`<br>`PATCH /api/items/:itemId/chat/:messageId`<br>`DELETE /api/items/:itemId/chat/:messageId`<br>`DELETE /api/items/:itemId/chat`<br>`POST /api/items/:id/actions`<br>`POST /api/items`<br>`PATCH /api/items/:id`<br>`DELETE /api/items`<br>`POST /api/items/move`<br>`POST /api/items/with-thumbnail` | 8 |
| `action_request_export` | `POST /api/items/:id/actions/export` | 0 |
| `app_action` | `POST /api/app-items/:itemId/app-action` | 3 |
| `app_data` | `POST /api/app-items/:itemId/app-data`<br>`PATCH /api/app-items/:itemId/app-data/:id`<br>`DELETE /api/app-items/:itemId/app-data/:id`<br>`POST /api/app-items/app-data/upload` | 4 |
| `app_setting` | `POST /api/app-items/:itemId/app-settings`<br>`PATCH /api/app-items/:itemId/app-settings/:id`<br>`DELETE /api/app-items/:itemId/app-settings/:id`<br>`POST /api/app-items/app-settings/upload`<br>`POST /api/items/zip-import`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` | 5 |
| `apps` | — | 3 |
| `chat_mention` | `PATCH /api/items/mentions/:mentionId`<br>`DELETE /api/items/mentions/:mentionId`<br>`DELETE /api/items/mentions`<br>`POST /api/items/:itemId/chat` | 2 |
| `chat_message` | `POST /api/items/:itemId/chat`<br>`PATCH /api/items/:itemId/chat/:messageId`<br>`DELETE /api/items/:itemId/chat/:messageId`<br>`DELETE /api/items/:itemId/chat` | 3 |
| `guest_password` | `POST /api/items/:id/login` | 0 |
| `guests_view` | — | 1 |
| `invitation` | `POST /api/register`<br>`POST /api/items/:id/invite`<br>`PATCH /api/items/:id/invitations/:invitationId`<br>`DELETE /api/items/:id/invitations/:invitationId`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv` | 3 |
| `item` | `POST /api/items/shortcuts`<br>`PATCH /api/items/shortcuts/:id`<br>`POST /api/items/:id/thumbnails`<br>`DELETE /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`PATCH /api/items/files/:id`<br>`POST /api/items/folders`<br>`PATCH /api/items/folders/:id`<br>`POST /api/items/folders/:id/convert`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/capsules/:id/convert`<br>`POST /api/items/apps`<br>`PATCH /api/items/apps/:id`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`PATCH /api/items/etherpad/:id`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id`<br>`POST /api/items/documents`<br>`PATCH /api/items/documents/:id`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/recycle`<br>`POST /api/items/restore`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`PATCH /api/items/:id`<br>`PATCH /api/items/:id/reorder`<br>`DELETE /api/items`<br>`POST /api/items/move`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` | 86 |
| `item_favorite` | `POST /api/items/bookmarks/:itemId`<br>`DELETE /api/items/bookmarks/:itemId` | 2 |
| `item_flag` | `POST /api/items/:itemId/flags` | 0 |
| `item_geolocation` | `POST /api/items/shortcuts`<br>`POST /api/items/upload`<br>`POST /api/items/folders`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/apps`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`POST /api/items/documents`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`PUT /api/items/:id/geolocation`<br>`DELETE /api/items/:id/geolocation`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` | 2 |
| `item_like` | `POST /api/items/:itemId/like`<br>`DELETE /api/items/:itemId/like` | 36 |
| `item_login_schema` | `PUT /api/items/:id/login-schema`<br>`DELETE /api/items/:id/login-schema` | 6 |
| `item_membership` | `POST /api/register`<br>`POST /api/items/:id/login`<br>`POST /api/items/:itemId/memberships`<br>`PATCH /api/items/:itemId/memberships/:id`<br>`DELETE /api/items/:itemId/memberships/:id`<br>`POST /api/items/shortcuts`<br>`POST /api/items/upload`<br>`POST /api/items/folders`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/apps`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`POST /api/items/documents`<br>`POST /api/items/:id/invite`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv`<br>`POST /api/items/:itemId/enroll`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`POST /api/items/move`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` | 97 |
| `item_tag` | `POST /api/items/:itemId/tags`<br>`DELETE /api/items/:itemId/tags/:tagId` | 34 |
| `item_validation` | `POST /api/items/:itemId/validate` | 0 |
| `item_validation_group` | `POST /api/items/:itemId/validate` | 3 |
| `item_validation_review` | `POST /api/items/:itemId/validate` | 0 |
| `item_view` | — | 116 |
| `item_visibility` | `POST /api/items/collections/:itemId/publish`<br>`POST /api/items/:itemId/visibilities/:type`<br>`DELETE /api/items/:itemId/visibilities/:type`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:itemId/validate`<br>`POST /api/items/copy` | 109 |
| `maintenance` | — | 1 |
| `member_password` | `POST /api/password`<br>`PATCH /api/password`<br>`PATCH /api/password/reset` | 2 |
| `member_profile` | `POST /api/members/profile`<br>`PATCH /api/members/profile` | 2 |
| `members_view` | — | 76 |
| `membership_request` | `POST /api/items/:itemId/memberships`<br>`POST /api/items/:itemId/memberships/requests`<br>`DELETE /api/items/:itemId/memberships/requests/:memberId`<br>`POST /api/items/:id/invite`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv` | 2 |
| `page_update` | `POST /api/items/:id/invitations/upload-csv-template`<br>`GET /api/items/pages/:id/ws/read`<br>`GET /api/items/pages/:id/ws`<br>`POST /api/items/copy` | 0 |
| `published_items` | `POST /api/items/collections/:itemId/publish`<br>`DELETE /api/items/collections/:itemId/unpublish`<br>`POST /api/items/:itemId/validate` | 37 |
| `publishers` | — | 1 |
| `recycled_item_data` | `POST /api/items/recycle`<br>`POST /api/items/restore` | 1 |
| `short_link` | `POST /api/items/short-links`<br>`DELETE /api/items/short-links/:alias`<br>`PATCH /api/items/short-links/:alias` | 3 |
| `tag` | `POST /api/items/:itemId/tags` | 35 |

## Websocket publications

Topic ← event, as published by the route.

| | Routes |
|---|---|
| `appActionsTopic ← AppActionEvent(post)` | `POST /api/app-items/:itemId/app-action` |
| `appDataTopic ← AppDataEvent(delete)` | `DELETE /api/app-items/:itemId/app-data/:id` |
| `appDataTopic ← AppDataEvent(patch)` | `PATCH /api/app-items/:itemId/app-data/:id` |
| `appDataTopic ← AppDataEvent(post)` | `POST /api/app-items/:itemId/app-data` |
| `appSettingsTopic ← AppSettingEvent(delete)` | `DELETE /api/app-items/:itemId/app-settings/:id` |
| `appSettingsTopic ← AppSettingEvent(patch)` | `PATCH /api/app-items/:itemId/app-settings/:id` |
| `appSettingsTopic ← AppSettingEvent(post)` | `POST /api/app-items/:itemId/app-settings` |
| `itemChatTopic ← ItemChatEvent(clear)` | `DELETE /api/items/:itemId/chat` |
| `itemChatTopic ← ItemChatEvent(delete)` | `DELETE /api/items/:itemId/chat/:messageId` |
| `itemChatTopic ← ItemChatEvent(publish)` | `POST /api/items/:itemId/chat` |
| `itemChatTopic ← ItemChatEvent(update)` | `PATCH /api/items/:itemId/chat/:messageId` |
| `itemMembershipsTopic ← ItemMembershipEvent(create)` | `POST /api/items/:itemId/memberships`<br>`POST /api/items/:id/invite`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv` |
| `itemMembershipsTopic ← ItemMembershipEvent(delete)` | `DELETE /api/items/:itemId/memberships/:id` |
| `itemMembershipsTopic ← ItemMembershipEvent(update)` | `PATCH /api/items/:itemId/memberships/:id` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(copy)` | `POST /api/items/copy` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(delete)` | `DELETE /api/items` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(export)` | `POST /api/items/:id/actions/export` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(move)` | `POST /api/items/move` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(recycle)` | `POST /api/items/recycle` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(restore)` | `POST /api/items/restore` |
| `memberItemsTopic ← ItemOpFeedbackErrorEvent(validate)` | `POST /api/items/:itemId/validate` |
| `memberItemsTopic ← ItemOpFeedbackEvent(copy)` | `POST /api/items/copy` |
| `memberItemsTopic ← ItemOpFeedbackEvent(delete)` | `DELETE /api/items` |
| `memberItemsTopic ← ItemOpFeedbackEvent(export)` | `POST /api/items/:id/actions/export` |
| `memberItemsTopic ← ItemOpFeedbackEvent(move)` | `POST /api/items/move` |
| `memberItemsTopic ← ItemOpFeedbackEvent(recycle)` | `POST /api/items/recycle` |
| `memberItemsTopic ← ItemOpFeedbackEvent(restore)` | `POST /api/items/restore` |
| `memberItemsTopic ← ItemOpFeedbackEvent(validate)` | `POST /api/items/:itemId/validate` |

## Emails

The function that triggers the email.

| | Routes |
|---|---|
| `ActionRequestExportService.sendExportLinkInMail` | `POST /api/items/:id/actions/export` |
| `AuthService.generateLoginLinkAndEmailIt` | `POST /api/register`<br>`POST /api/login` |
| `AuthService.generateRegisterLinkAndEmailIt` | `POST /api/register` |
| `ExportMemberDataService.sendExportLinkInMail` | `POST /api/members/export-data` |
| `InvitationService.sendInvitationEmail` | `POST /api/items/:id/invite`<br>`POST /api/items/:id/invitations/:invitationId/send`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv` |
| `ItemMembershipService._notifyMember` | `POST /api/items/:itemId/memberships`<br>`POST /api/items/:id/invite`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv` |
| `ItemPublishedService._notifyContributors` | `POST /api/items/collections/:itemId/publish`<br>`POST /api/items/:itemId/validate` |
| `MemberPasswordService.mailResetPasswordRequest` | `POST /api/password/reset` |
| `MemberService.mailConfirmEmailChangeRequest` | `PATCH /api/members/current/email/change` |
| `MemberService.sendEmailChangeRequest` | `POST /api/members/current/email/change` |
| `MembershipRequestService.notifyAdmins` | `POST /api/items/:itemId/memberships/requests` |
| `MentionService.sendMentionNotificationEmail` | `POST /api/items/:itemId/chat` |

## Background jobs

| | Routes |
|---|---|
| `Queues.ItemExport.jobs.exportFolderZip` | `POST /api/items/:itemId/export` |
| `Queues.SearchIndex.jobs.buildIndex` | `POST /api/items/collections/:itemId/publish`<br>`DELETE /api/items/collections/:itemId/unpublish`<br>`GET /api/items/collections/search/rebuild`<br>`POST /api/items/shortcuts`<br>`PATCH /api/items/shortcuts/:id`<br>`POST /api/items/:id/thumbnails`<br>`DELETE /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`PATCH /api/items/files/:id`<br>`POST /api/items/folders`<br>`PATCH /api/items/folders/:id`<br>`POST /api/items/folders/:id/convert`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/capsules/:id/convert`<br>`POST /api/items/apps`<br>`PATCH /api/items/apps/:id`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`PATCH /api/items/etherpad/:id`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id`<br>`POST /api/items/documents`<br>`PATCH /api/items/documents/:id`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/tags`<br>`DELETE /api/items/:itemId/tags/:tagId`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`PATCH /api/items/:id`<br>`POST /api/items/move`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` |

## File storage

| | Routes |
|---|---|
| `file:copy` | `POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` |
| `file:copyFolder` | `POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` |
| `file:delete` | `DELETE /api/app-items/:itemId/app-data/:id`<br>`DELETE /api/app-items/:itemId/app-settings/:id`<br>`DELETE /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`POST /api/items/zip-import`<br>`DELETE /api/items` |
| `file:deleteFolder` | `POST /api/items/upload`<br>`POST /api/items/h5p-import`<br>`POST /api/items/zip-import`<br>`DELETE /api/items` |
| `file:getFile` | `POST /api/items/:itemId/graasp-export` |
| `file:getFileSize` | `POST /api/items/upload`<br>`POST /api/items/zip-import` |
| `file:getUrl` | `GET /api/members/:id/avatar/:size`<br>`POST /api/members/export-data`<br>`GET /api/app-items/app-data/:id/download`<br>`GET /api/app-items/app-settings/:id/download`<br>`GET /api/items/bookmarks`<br>`GET /api/items/collections/members/:memberId`<br>`POST /api/items/collections/search`<br>`GET /api/items/collections/featured`<br>`GET /api/items/collections/liked`<br>`GET /api/items/collections/recent`<br>`GET /api/items/:id/thumbnails/:size`<br>`GET /api/items/:id/download`<br>`GET /api/items/:itemId/download-file`<br>`POST /api/items/:itemId/graasp-export`<br>`POST /api/items/:itemId/validate`<br>`POST /api/items/:id/actions/export`<br>`GET /api/items/:id/geolocation`<br>`GET /api/items/geolocation`<br>`GET /api/items/:id`<br>`GET /api/items/accessible`<br>`GET /api/items/:id/children`<br>`GET /api/items/:id/descendants` |
| `file:upload` | `POST /api/members/export-data`<br>`POST /api/app-items/app-data/upload`<br>`POST /api/app-items/app-settings/upload`<br>`POST /api/items/upload`<br>`POST /api/items/h5p-import`<br>`POST /api/items/zip-import`<br>`POST /api/items/:id/actions/export` |
| `file:uploadMany` | `POST /api/members/avatar`<br>`POST /api/items/shortcuts`<br>`POST /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`POST /api/items/folders`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/apps`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`POST /api/items/documents`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`POST /api/items/with-thumbnail` |

## Search index

`write` updates the Meilisearch index, `query` searches it.

| | Routes |
|---|---|
| `query:meilisearch.multiSearch` | `POST /api/items/collections/search`<br>`POST /api/items/collections/facets`<br>`GET /api/items/collections/featured`<br>`GET /api/items/collections/liked`<br>`GET /api/items/collections/recent` |
| `query:search` | `POST /api/items/collections/search`<br>`POST /api/items/collections/facets`<br>`GET /api/items/collections/featured`<br>`GET /api/items/collections/liked`<br>`GET /api/items/collections/recent` |
| `write:deleteOne` | `DELETE /api/items/collections/:itemId/unpublish`<br>`POST /api/items/move` |
| `write:index` | `POST /api/items/collections/:itemId/publish`<br>`POST /api/items/shortcuts`<br>`PATCH /api/items/shortcuts/:id`<br>`POST /api/items/:id/thumbnails`<br>`DELETE /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`PATCH /api/items/files/:id`<br>`POST /api/items/folders`<br>`PATCH /api/items/folders/:id`<br>`POST /api/items/folders/:id/convert`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/capsules/:id/convert`<br>`POST /api/items/apps`<br>`PATCH /api/items/apps/:id`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`PATCH /api/items/etherpad/:id`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id`<br>`POST /api/items/documents`<br>`PATCH /api/items/documents/:id`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/tags`<br>`DELETE /api/items/:itemId/tags/:tagId`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`PATCH /api/items/:id`<br>`POST /api/items/move`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` |
| `write:indexOne` | `POST /api/items/collections/:itemId/publish`<br>`POST /api/items/shortcuts`<br>`PATCH /api/items/shortcuts/:id`<br>`POST /api/items/:id/thumbnails`<br>`DELETE /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`PATCH /api/items/files/:id`<br>`POST /api/items/folders`<br>`PATCH /api/items/folders/:id`<br>`POST /api/items/folders/:id/convert`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/capsules/:id/convert`<br>`POST /api/items/apps`<br>`PATCH /api/items/apps/:id`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`PATCH /api/items/etherpad/:id`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id`<br>`POST /api/items/documents`<br>`PATCH /api/items/documents/:id`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/tags`<br>`DELETE /api/items/:itemId/tags/:tagId`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`PATCH /api/items/:id`<br>`POST /api/items/move`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` |
| `write:meilisearch.addDocuments` | `POST /api/items/collections/:itemId/publish`<br>`POST /api/items/shortcuts`<br>`PATCH /api/items/shortcuts/:id`<br>`POST /api/items/:id/thumbnails`<br>`DELETE /api/items/:id/thumbnails`<br>`POST /api/items/upload`<br>`PATCH /api/items/files/:id`<br>`POST /api/items/folders`<br>`PATCH /api/items/folders/:id`<br>`POST /api/items/folders/:id/convert`<br>`POST /api/items/folders-with-thumbnail`<br>`POST /api/items/capsules`<br>`POST /api/items/capsules/:id/convert`<br>`POST /api/items/apps`<br>`PATCH /api/items/apps/:id`<br>`POST /api/items/h5p-import`<br>`POST /api/items/etherpad/create`<br>`PATCH /api/items/etherpad/:id`<br>`POST /api/items/zip-import`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id`<br>`POST /api/items/documents`<br>`PATCH /api/items/documents/:id`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/tags`<br>`DELETE /api/items/:itemId/tags/:tagId`<br>`POST /api/items/pages`<br>`POST /api/items`<br>`PATCH /api/items/:id`<br>`POST /api/items/move`<br>`POST /api/items/copy`<br>`POST /api/items/with-thumbnail` |
| `write:meilisearch.deleteDocuments` | `DELETE /api/items/collections/:itemId/unpublish`<br>`POST /api/items/move` |
| `write:meilisearch.index` | `POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/like`<br>`DELETE /api/items/:itemId/like` |
| `write:meilisearch.updateDocuments` | `POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/like`<br>`DELETE /api/items/:itemId/like` |
| `write:updateItem` | `POST /api/items/:itemId/validate`<br>`POST /api/items/:itemId/like`<br>`DELETE /api/items/:itemId/like` |

## External services

| | Routes |
|---|---|
| `etherpad:EtherpadItemService.createEtherpadItem` | `POST /api/items/etherpad/create` |
| `etherpad:EtherpadItemService.createPad` | `POST /api/items/etherpad/create`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` |
| `etherpad:EtherpadItemService.deleteEtherpadForItem` | `DELETE /api/items` |
| `etherpad:EtherpadItemService.getEtherpadContentFromItem` | `GET /api/items/:itemId/download-file`<br>`POST /api/items/:itemId/graasp-export` |
| `etherpad:EtherpadItemService.getEtherpadFromItem` | `GET /api/items/etherpad/view/:itemId` |
| `http:EmbeddedLinkItemService.checkEmbeddingAllowed` | `GET /api/items/embedded-links/metadata` |
| `http:EmbeddedLinkItemService.getLinkMetadata` | `GET /api/items/embedded-links/metadata`<br>`POST /api/items/embedded-links`<br>`PATCH /api/items/embedded-links/:id` |
| `http:ItemExportService.fetchItemData` | `GET /api/items/:itemId/download-file`<br>`POST /api/items/:itemId/graasp-export` |
| `http:ItemGeolocationRepository.getAddressFromCoordinates` | `GET /api/items/geolocation/reverse` |
| `http:ItemGeolocationRepository.getSuggestionsForQuery` | `GET /api/items/geolocation/search` |
| `http:sendRequestToClassifier` | `POST /api/items/:itemId/validate` |
| `http:validateCaptcha` | `POST /api/register`<br>`POST /api/login`<br>`POST /api/login-password`<br>`POST /api/password/reset` |
| `openai:openAICompletion` | `POST /api/app-items/:itemId/chat-bot` |
| `redis` | `GET /api/bust-cache`<br>`POST /api/password/reset`<br>`PATCH /api/password/reset`<br>`POST /api/items/collections/:itemId/publish`<br>`GET /api/items/publication/:itemId/status`<br>`POST /api/items/:itemId/validate` |

## Service hooks

`Service:phase:event` hooks fired, with handlers registered in another module.

| | Routes |
|---|---|
| `AppSettingService:post:copyMany` | `POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` |
| `AppSettingService:post:delete` | `DELETE /api/app-items/:itemId/app-settings/:id` |
| `ItemMembershipService:post:create` | `POST /api/items/:itemId/memberships`<br>`POST /api/items/:id/invite`<br>`POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/:id/invitations/upload-csv` |
| `ItemMembershipService:post:delete` | `DELETE /api/items/:itemId/memberships/:id` |
| `ItemMembershipService:post:update` | `PATCH /api/items/:itemId/memberships/:id` |
| `ItemPublishedService:post:delete` | `DELETE /api/items/collections/:itemId/unpublish` |
| `ItemService:post:copy` | `POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` |
| `ItemService:post:delete` | `DELETE /api/items` |
| `ItemService:pre:copy` | `POST /api/items/:id/invitations/upload-csv-template`<br>`POST /api/items/copy` |
| `ItemService:pre:delete` | `DELETE /api/items` |
