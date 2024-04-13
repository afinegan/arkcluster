build:
	docker build -f Dockerfile . -t afinegan/arkcluster:dev

clean:
	docker image rm afinegan/arkcluster:dev ||:

push:
	docker image push afinegan/arkcluster:dev

all: clean build push
