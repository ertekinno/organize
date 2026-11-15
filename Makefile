# Python 3.10–3.12 (fontbakery does not install on 3.13 yet).
PYTHON ?= $(shell command -v python3.12 || command -v python3)
SOURCES=$(shell python3 scripts/read-config.py --sources)
FAMILY=$(shell python3 scripts/read-config.py --family)

help:
	@echo "###"
	@echo "# Build targets for $(FAMILY)"
	@echo "###"
	@echo
	@echo "  make build:  Builds the fonts and places them in the fonts/ directory"
	@echo "  make test:   Tests the fonts with fontbakery (Google Fonts profile)"
	@echo "  make proof:  Creates HTML proof documents in the out/proof/ directory"
	@echo "  make clean:  Removes the virtual environment and build intermediates"
	@echo

build: build.stamp

venv: venv/touchfile

build.stamp: venv sources/config.yaml $(SOURCES)
	rm -rf fonts
	(for config in sources/config*.yaml; do . venv/bin/activate; gftools builder $$config; done) && touch build.stamp

venv/touchfile: requirements.txt
	test -d venv || $(PYTHON) -m venv venv
	. venv/bin/activate; pip install -Ur requirements.txt
	touch venv/touchfile

# Variable and static fonts are checked separately: checked together, fontbakery
# treats them as one family and reports family-level problems that don't apply.
FB = fontbakery check-googlefonts -l WARN --full-lists --succinct
FB_WARN = echo '::warning file=sources/config.yaml,title=Fontbakery failures::The fontbakery QA check reported errors in your font. Please check the generated report.'

test: venv build.stamp
	. venv/bin/activate; mkdir -p out/fontbakery; \
	$(FB) --badges out/badges --html out/fontbakery/fontbakery-report.html --ghmarkdown out/fontbakery/fontbakery-report.md fonts/variable/*.ttf || $(FB_WARN); \
	$(FB) --html out/fontbakery/fontbakery-report-static.html --ghmarkdown out/fontbakery/fontbakery-report-static.md fonts/ttf/*.ttf || $(FB_WARN)

proof: venv build.stamp
	. venv/bin/activate; mkdir -p out/ out/proof; diffenator2 proof $(shell find fonts/ttf -type f -name '*.ttf') -o out/proof

clean:
	rm -rf venv build.stamp out
	find . -name "*.pyc" -delete
	rm -rf sources/build.ninja sources/.ninja_log sources/instance_ufos

update:
	pip install --upgrade $(dependency); pip freeze > requirements.txt

.PHONY: help build venv test proof clean update
