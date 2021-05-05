FROM golang:1.16

#COPY ./isubata /home/isucon/isubata
COPY ./isubata/webapp/go /home/isucon/isubata/webapp/go
WORKDIR /home/isucon/isubata/webapp/go/
RUN go mod download

RUN go build -o ../isubata src/isubata/app.go
EXPOSE 5000
EXPOSE 6060

ENTRYPOINT ["/home/isucon/isubata/webapp/isubata"]
