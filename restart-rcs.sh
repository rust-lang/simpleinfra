set -o errexit
set -o pipefail
set -o nounset

RCS_DATA=$(pwd)/rcs-data
if [ ! -d "$RCS_DATA" ]; then
	echo "No rcs dir '$RCS_DATA'"
	exit 1
fi

#ssh $USER@rcs.rust-lang.org '
bash -c '
	sudo mkdir -p /opt/rcs &&
	chown $USER: /opt/rcs
'
#rsync -avr --delete rcs-data/ $USER@rcs.rust-lang.org:/opt/rcs/data/
rsync -avr --delete rcs-data/ /opt/rcs/data/
#ssh $USER@rcs.rust-lang.org '
bash -c '
	set -o errexit &&
	set -o pipefail &&
	set -o nounset &&
	sudo mkdir -p /opt/rcs &&
	chown $USER: /opt/rcs &&
	cd /opt/rcs &&
	docker pull alexcrichton/rust-central-station &&
	(docker rm -f rcs || true) &&
	docker run \
		--name rcs \
        --volume `pwd`/data:/data \
        --volume `pwd`/data/letsencrypt:/etc/letsencrypt \
        --volume `pwd`/logs:/var/log \
        --publish 80:80 \
        --publish 443:443 \
        --rm \
        --detach \
        alexcrichton/rust-central-station
'
