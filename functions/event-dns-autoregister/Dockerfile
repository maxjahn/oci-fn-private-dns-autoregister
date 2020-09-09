FROM maxjahn/fn-go:dev as build-stage
WORKDIR /function
WORKDIR /go/src/func/
ENV GO111MODULE=on
COPY . .
RUN cd /go/src/func/ && go build -o func
FROM maxjahn/fn-go
WORKDIR /function
COPY --from=build-stage /go/src/func/func /function/
ENTRYPOINT ["./func"]