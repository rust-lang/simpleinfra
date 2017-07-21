ssh $USER@robots.rust-lang.org '
	docker rm -f bors &&
	docker pull rust-lang/bors &&
	docker run -d -p 80:80 rust-lang/bors --name bors
'
