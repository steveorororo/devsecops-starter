FROM node:20

ENV DATABASE_HOST=prod-db.workstream.internal
ENV DATABASE_PASSWORD=s3cret_pr0d_passw0rd!
ENV AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
ENV AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

WORKDIR /app

COPY . .

RUN npm install 2>/dev/null || true

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    net-tools \
    netcat-openbsd \
    tcpdump \
    strace \
    ssh \
    telnet

EXPOSE 3000

CMD ["node", "server.js"]
