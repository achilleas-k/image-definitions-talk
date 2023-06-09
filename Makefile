.PHONY: present static clean

ip := 172.17.0.2
reveal-md := docker run -d --ip="${ip}" --rm --user="$(shell id -u):$(shell id -g)" -v .:/slides --name presentation webpronl/reveal-md:latest

present:
	$(reveal-md) /slides/presentation/slides.md --disable-auto-open
	@echo "SLIDES: http://${ip}:1948/slides.md"
	docker attach presentation > /dev/null

html: ./presentation/slides.md ./presentation/style.css
	$(reveal-md) /slides/presentation/slides.md --static /slides/html
	docker attach presentation

static: html

clean:
	rm -rv ./html
