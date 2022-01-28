APP := redisolar
PORT := 8081
PYTHON3_8 := $(shell command -v python3.8 2> /dev/null)

ifndef PYTHON3_8
    $(error "Python 3.8 is not installed! See README.md")
endif

ifeq (${IS_CI}, true)
	FLAGS := "--ci"
else
	FLAGS := "-s"
endif

.PHONY: mypy test all clean dev load frontend timeseries-docker deps

all: venv mypy lint test

venv: venv/bin/activate

venv/bin/activate: requirements.txt
	test -d env || python3.8 -m venv venv
	. venv/bin/activate; pip install --upgrade pip; pip install pip-tools wheel -e .; pip-sync requirements.txt requirements-dev.txt
	touch venv/bin/activate

mypy: venv
	. venv/bin/activate; mypy --ignore-missing-imports redisolar

test: venv
	. venv/bin/activate; pytest $(FLAGS)

lint: venv
	. venv/bin/activate; pylint redisolar

clean:
	rm -rf venv
	find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete

dev: venv
	. venv/bin/activate; FLASK_ENV=development FLASK_APP=$(APP) FLASK_DEBUG=1 flask run --port=$(PORT) --host=0.0.0.0

requirements.txt: requirements.in
	pip-compile requirements.in > requirements.txt

requirements-dev.txt: requirements-dev.in
	pip-compile requirements-dev.in > requirements-dev.txt

deps: requirements-dev.txt requirements.txt

frontend: venv
	cd frontend; npm run build
	rm -rf redisolar/static
	cp -r frontend/dist/static redisolar/static
	cp frontend/dist/index.html redisolar/static/

load: venv
	. venv/bin/activate; FLASK_APP=$(APP) flask load

timeseries-docker:
	docker run -p 6379:6379 -it -d --rm redislabs/redistimeseries

timeseries-podman:
	podman run -p 6379:6379 -it -d --rm redislabs/redistimeseries
