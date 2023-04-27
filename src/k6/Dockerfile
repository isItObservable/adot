FROM grafana/k6:latest
WORKDIR /load
COPY --chown=root:root ./load.js ./load.js
COPY ./batman-lego.jpg ./batman-lego.jpg
ENTRYPOINT ["k6","run","/load/load.js"]