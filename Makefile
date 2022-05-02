.PHONY: quality  help requirements\
	piptools selfcheck  upgrade test clean

.DEFAULT_GOAL := help

piptools: ## install pinned version of pip-compile and pip-sync
	pip install -r requirements/pip-tools.txt

help: ## display this help message
	@echo "Please use \`make <target>' where <target> is one of"
	@awk -F ':.*?## ' '/^[a-zA-Z]/ && NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

# Define PIP_COMPILE_OPTS=-v to get more information during make upgrade.
PIP_COMPILE = pip-compile --upgrade $(PIP_COMPILE_OPTS)

clean: ## remove generated byte code, coverage reports, and build artifacts
	find tutorcodejail -name '__pycache__' -exec rm -rf {} +
	find tutorcodejail -name '*.pyc' -exec rm -f {} +
	find tutorcodejail -name '*.pyo' -exec rm -f {} +
	find tutorcodejail -name '*~' -exec rm -f {} +
	coverage erase
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info


upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: ## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	make piptools
	# Make sure to compile files after any other files they include!
	$(PIP_COMPILE) --allow-unsafe --rebuild -o requirements/pip.txt requirements/pip.in
	$(PIP_COMPILE) -o requirements/pip-tools.txt requirements/pip-tools.in
	make piptools
	$(PIP_COMPILE) -o requirements/base.txt requirements/base.in
	$(PIP_COMPILE) -o requirements/dev.txt requirements/dev.in

quality: ## check coding style with pycodestyle and pylint
	pylint tutorcodejail *.py
	pycodestyle tutorcodejail *.py
	pydocstyle tutorcodejail *.py
	isort --check-only --diff --recursive tutorcodejail *.py
	python setup.py bdist_wheel
	twine check dist/*
	make selfcheck

requirements: ## install development environment requirements
	pip install -r requirements/pip.txt
	pip install -r requirements/pip-tools.txt
	pip-sync requirements/dev.txt
	pip install -e .

test: ## run unitary tests and meassure coverage
	coverage run -m pytest
	coverage report -m --fail-under=62
	@echo "Testing module buiding..."

selfcheck: ## check that the Makefile is well-formed
	@echo "The Makefile is well-formed."