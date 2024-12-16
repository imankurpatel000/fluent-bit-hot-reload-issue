all:
	docker run --rm -v "$(PWD)":/app -w /app --platform linux/arm64 golang:1.20-bullseye go build -buildmode=c-shared -o ./bin/out_multiinstance.so

clean:
	rm -rf ./bin/*