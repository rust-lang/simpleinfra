set -o errexit
set -o pipefail
set -o nounset

NEWUSER="$1"
echo "$NEWUSER" >> users
for server in $(cat server); do
	ssh $USER@$server "useradd $user"
	# TODO: also add to docker group
done
