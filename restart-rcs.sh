ssh $USER@rcs.rust-lang.org '
	docker rm -f rcs &&
	docker pull rust-lang/rcs &&
	docker run -d -p 80:80 rust-lang/rcs --name rcs
'
