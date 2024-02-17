export GO111MODULE := on
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=amd64

SOURCES := $(shell find $(SOURCEDIR) -name '*.go')

all: lint build

################################################################################
### Builds
###

build:
	go build -o qtdeploy ./cmd/qtdeploy/main.go
	go build -o qtminimal ./cmd/qtminimal/main.go
	go build -o qtmoc ./cmd/qtmoc/main.go
	go build -o qtrcc ./cmd/qtrcc/main.go
	go build -o qtsetup ./cmd/qtsetup/main.go

run:
	make build
	./cmd/gt_calibr/deploy/linux/gt_calibr

deploy:
	qtdeploy -ldflags="-X github.com/GravTechnology/gt_calibr/internal/version.version=$(VERSION) -X github.com/GravTechnology/gt_calibr/internal/version.commit=$(COMMIT) -X github.com/GravTechnology/gt_calibr/internal/version.branch=$(BRANCH) -X github.com/GravTechnology/gt_calibr/internal/version.buildUnixTimestamp=$(BUILD_TIME) -X github.com/GravTechnology/gt_calibr/internal/version.builder=$(BUILDER)" -docker build windows_64_static ./cmd/$(TARGET)/
	cp -r templates ./cmd/gt_calibr/deploy/windows/templates
################################################################################
### Linters
###
lint: tidy
	gofumpt -w .
	gci write . --skip-generated -s standard -s default
	golangci-lint run


linters: golangci-lint

golangci-lint: build
	test $(TARGET) != golang-template-project && grep -r --exclude-dir='.git' 'golang-template-project' | grep -v 'should be absent in normal project' && echo "all golang-template-project should be absent in normal project" && exit 1 || :
	find -type f -name "*.go" | grep -v '.*\.pb\.go' | grep -v '\/[a-z_]*.go' && echo "Files should be named in snake case" && exit 1 || echo "All files named in snake case"
	golangci-lint version
	golangci-lint run

################################################################################
### Golang helpers
###
vendor:
	go mod vendor -v

modup:
	go get -u ./...
	go mod tidy

tidy:
	go mod tidy -v

clean:
	rm -rf bin/$(TARGET)

image:
	docker build ./docker/windows_64_static/. -t akaddr/qt:windows_64_static
	docker build ./docker/windows_64_shared/. -t akaddr/qt:windows_64_shared

doc:
	xelatex ./docs/manual.tex

pdf:
	pandoc --pdf-engine=xelatex -V mainfont="Times New Roman" --from markdown --output readme.pdf readme.md

tar:
	touch gt_calibr_$(VERSION).tar.gz
	tar -czvf gt_calibr_$(VERSION).tar.gz --exclude=.git --exclude=.idea --exclude=gt_calibr_$(VERSION).tar.gz ./