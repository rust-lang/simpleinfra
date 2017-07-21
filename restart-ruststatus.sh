ssh $USER@robots.rust-lang.org '
	docker rm -f ruststatus &&
	docker pull rust-lang/ruststatus &&
	docker run -d -p 80:80 rust-lang/ruststatus --name ruststatus
'
