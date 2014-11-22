# Merge requests

## List merge requests

Get all merge requests for this project. The `state` parameter can be used to get only merge requests with a given state (`opened`, `closed`, or `merged`) or all of them (`all`). The pagination parameters `page` and `per_page` can be used to restrict the list of merge requests.

```
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
```

Parameters:

- `id` (required) - The ID of a project
- `state` (optional) - Return `all` requests or just those that are `merged`, `opened` or `closed`
- `order_by` (optional) - Return requests ordered by `created_at` or `updated_at` fields
- `sort` (optional) - Return requests sorted in `asc` or `desc` order

```json
[
  {
    "id": 1,
    "iid": 1,
    "target_branch": "master",
    "source_branch": "test1",
    "project_id": 3,
    "title": "test1",
    "state": "opened",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2012-04-29T08:46:00Z"
    },
    "assignee": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2012-04-29T08:46:00Z"
    },
    "description":"fixed login page css paddings"
  }
]
```

## Get single MR

Shows information about a single merge request.

```
GET /projects/:id/merge_request/:merge_request_id
```

Parameters:

- `id` (required) - The ID of a project
- `merge_request_id` (required) - The ID of MR

```json
{
  "id": 1,
  "iid": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "merged",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "description":"fixed login page css paddings"
}
```

## Create MR

Creates a new merge request.

```
POST /projects/:id/merge_requests
```

Parameters:

- `id` (required)                - The ID of a project
- `source_branch` (required)     - The source branch
- `target_branch` (required)     - The target branch
- `assignee_id` (optional)       - Assignee user ID
- `title` (required)             - Title of MR
- `target_project_id` (optional) - The target project (numeric id)

```json
{
  "id": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "opened",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "description":"fixed login page css paddings"
}
```

If the operation is successful, 200 and the newly created merge request is returned.
If an error occurs, an error number and a message explaining the reason is returned.

## Update MR

Updates an existing merge request. You can change branches, title, or even close the MR.

```
PUT /projects/:id/merge_request/:merge_request_id
```

Parameters:

- `id` (required)               - The ID of a project
- `merge_request_id` (required) - ID of MR
- `source_branch`               - The source branch
- `target_branch`               - The target branch
- `assignee_id`                 - Assignee user ID
- `title`                       - Title of MR
- `state_event`                 - New state (close|reopen|merge)

```json
{
  "id": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "opened",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  }
}
```

If the operation is successful, 200 and the updated merge request is returned.
If an error occurs, an error number and a message explaining the reason is returned.

## Accept MR

Merge changes submitted with MR using this API.

If merge success you get `200 OK`.

If it has some conflicts and can not be merged - you get 405 and error message 'Branch cannot be merged'

If merge request is already merged or closed - you get 405 and error message 'Method Not Allowed'

If you don't have permissions to accept this merge request - you'll get a 401

```
PUT /projects/:id/merge_request/:merge_request_id/merge
```

Parameters:

- `id` (required)                   - The ID of a project
- `merge_request_id` (required)     - ID of MR
- `merge_commit_message` (optional) - Custom merge commit message

```json
{
  "id": 1,
  "target_branch": "master",
  "source_branch": "test1",
  "project_id": 3,
  "title": "test1",
  "state": "merged",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  },
  "assignee": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "state": "active",
    "created_at": "2012-04-29T08:46:00Z"
  }
}
```

## Post comment to MR

Adds a comment to a merge request.

```
POST /projects/:id/merge_request/:merge_request_id/comments
```

Parameters:

- `id` (required)               - The ID of a project
- `merge_request_id` (required) - ID of merge request
- `note` (required)             - Text of comment

```json
{
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Administrator",
    "blocked": false,
    "created_at": "2012-04-29T08:46:00Z"
  },
  "note": "text1"
}
```

## Get the comments on a MR

Gets all the comments associated with a merge request.

```
GET /projects/:id/merge_request/:merge_request_id/comments
```

Parameters:

- `id` (required)               - The ID of a project
- `merge_request_id` (required) - ID of merge request

```json
[
  {
    "note": "this is the 1st comment on the 2merge merge request",
    "author": {
      "id": 11,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2014-03-06T08:17:35.000Z"
    }
  },
  {
    "note": "_Status changed to closed_",
    "author": {
      "id": 11,
      "username": "admin",
      "email": "admin@example.com",
      "name": "Administrator",
      "state": "active",
      "created_at": "2014-03-06T08:17:35.000Z"
    }
  }
]
```

## Comments on issues

Comments are done via the notes resource.
