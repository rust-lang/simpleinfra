# `postgresql` role

This role installs and configures a PostgreSQL database on the instance. It
also allows creating databases and users in it. The database is **not** backed
up.

## Configuration

```yaml
- role: postgresql

  # PostgreSQL users to create on the server. [optional]
  # If missing no users will be created by the role.
  users:
    # Name of the user. If it's the same as a system user peer authentication
    # will be available.
    foo:
      # Password used by the user to authenticate.
      # If the password is missing only peer authentication will be available.
      password: bar
    # ...multiple users are allowed.

  # PostgreSQL databases to create on the server. [optional]
  # If missing no databases will be created by the role.
  databases:
    # Name of the database. If it's the same as the name of an user it will be
    # the default database for that user.
    baz:
      # User owning the database, who will have full permissions on it.
      owner: foo
      # Encoding used to store the data in the database.
      encoding: UTF-8
    # ...multiple databases are allowed.
```
