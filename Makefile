# Makefile for the SIMPOS project

all:
	echo Targets: build git run clean

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

clean:
	./sh/clean.sh

isobuild:
	./sh/mkiso.sh

runiso:
	./sh/runiso.sh

