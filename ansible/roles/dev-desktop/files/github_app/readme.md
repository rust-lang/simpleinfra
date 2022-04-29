# How to setup an App

1. Go to https://github.com/settings/apps
2. New Github App
3. Fill out metadata (name and url)
4. disable WebHook checkbox
5. Set `Contents - Repository contents, commits, branches, downloads, releases, and merges.` to read/write
6. Set to "enable on any account"
7. Create App

# How to generate a .pem file for your App

1. Go to https://github.com/settings/apps/{your_app_name_here}#private-key and generate a private key
2. Download starts, save it to somewhere private.
3. copy the .pem file into the same folder as the `gen_temp_access_token.py` and name it `dev-desktop.private-key.pem`

# How to install the app for a user

1. direct the user to https://github.com/settings/apps/{your_app_name_here}/installations
2. let them install it on the org/user they want to and restrict to the repositories they want to use

# How to setup the app

1. Go to https://github.com/settings/apps/{your_app_name_here} and copy the `App ID` into `app_id.txt`

# How to generate a temporary access token for a specific user

1. invoke `gen_temp_access_token.py <github_username> <github_repository_name>`
