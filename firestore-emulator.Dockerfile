FROM debian:latest

RUN \
      apt-get update -qq && \
      apt-get install -y default-jre curl &&\
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* &&\
      curl -sL 'https://firebase.tools/bin/linux/latest' > firebase
RUN \
      chmod +x ./firebase &&\
      echo '{ "emulators": { "firestore": { "host": "0.0.0.0" } } }' > firebase.json &&\
      ./firebase setup:emulators:firestore

EXPOSE 8080

# CMD ["./firebase", "emulators:start", "--only", "firestore"]
CMD ./firebase emulators:start --only firestore
