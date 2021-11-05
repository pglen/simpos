# Makefile for the SIMPOS project

all:
	echo Targets: build git run clean isobuild isorun

# Auto Checkin
ifeq ("$(AUTOCHECK)","")
AUTOCHECK=autocheck
endif

git:
	git add .
	git commit -m "$(AUTOCHECK)"
	git push

build:
	./sh/build.sh

run:  build
	./sh/run.sh

jump:  build
	./sh/install-jump.sh

clean:
	./sh/clean.sh

isobuild:  build
	./sh/mkiso.sh

isorun:  isobuild
	./sh/runiso.sh

runiso:
	./sh/runiso.sh

