set -o errexit
set -o pipefail
set -o nounset

NEWSERVER="$1"
echo "$NEWSERVER" >> servers
for user in $(cat users); do
	ssh $USER@$NEWSERVER "useradd $user"
	# TODO: also add to docker group
done
