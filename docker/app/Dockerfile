FROM golang:1.16

#ARG GIT_URL=https://github.com/isucon/isucon7-qualify.git

#RUN git clone $GIT_URL /home/isucon/isubata
COPY ./isubata /home/isucon/isubata
WORKDIR /home/isucon/isubata/webapp/go/src/isubata
#RUN make
RUN go mod download

RUN go build
EXPOSE 5000
EXPOSE 6060

ENTRYPOINT ["/home/isucon/isubata/webapp/go/src/isubata/isubata"]
