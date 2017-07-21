ssh $USER@play.rust-lang.org '
	docker rm -f playground &&
	docker pull rust-lang/playground &&
	docker run -d -p 80:80 rust-lang/playground --name playground
'
