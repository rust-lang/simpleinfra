resource "google_project_iam_member" "iam_admins" {
  for_each = toset(var.admins)

  project = var.project_id
  role    = "roles/owner"
  member  = "user:${each.value}"
}

resource "google_project_iam_member" "iam_viewers" {
  for_each = toset(var.viewers)

  project = var.project_id
  role    = "roles/viewer"
  member  = "user:${each.value}"
}
